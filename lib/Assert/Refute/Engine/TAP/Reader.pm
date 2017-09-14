package Assert::Refute::Engine::TAP::Reader;

use strict;
use warnings;
our $VERSION = 0.03;

=head1 NAME

Assert::Refute::Engine::TAP::Reader - test anything protocol parser for Assert::Refute

=head1 DESCRIPTION

This module is a L<Assert::Refute> that, instead of executing
tests, reads those from a TAP stream.

Additional tests are performed on the recieving end (ok's in order, plan
present etc).

=head1 METHODS

=cut

use Carp;
use parent qw(Assert::Refute);

=head2 new( in => $fd | exec => "command" | eval => sub { CODE; } )

Create a new TAP reader object.

=cut

# TODO Way too complex, should be in helper subs instead

sub _NEWOPTIONS { __PACKAGE__->SUPER::_NEWOPTIONS, qw(in pid) };
sub new {
    my ($class, %opt) = @_;

    1 == scalar grep { $opt{$_} } qw(in exec eval) # TODO better names
        or croak "$class->new: exactly one of (in, exec, eval) required";

    if ($opt{exec}) {
        $opt{exec} = [ $opt{exec} ]
            unless ref $opt{exec} eq 'ARRAY';
        my $pid   = open (my $fd, "-|", @{ $opt{exec} })
            or croak "$class->new: Failed to read from cmd: $opt{exec}[0]: $!";
        $opt{in}  = $fd;
        $opt{pid} = $pid;
    }
    elsif ($opt{eval}) {
        pipe my $f_r, my $f_w;
        my $pid = fork;
        croak "$class->new: fork() failed: $!"
            unless defined $pid;
        if (!$pid) {
            # CHILD SECTION
            close $f_r;
            if ($opt{replace_stdout}) {
                open STDOUT, ">&", $f_w
                    or die "Failed to redirect stdout to pipe: $!";
                $f_w = \*STDOUT;
            };
            $opt{eval}->($f_w);
            exit;
            # CHILD SECTION ENDS
        };
        close $f_w;
        $opt{in} = $f_r;
        $opt{pid} = $pid;
    };

    return $class->SUPER::new(%opt);
};

=head2 read_line( $line )

Read and parse one line of TAP input. State machine involved.

Done this way to allow for future async invocation.

=cut

# parse?
sub read_line {
    my ($self, $line) = @_;

    chomp $line;

#    warn "Got line: $line\n";
    # state machine!
    if ($line =~ /^(not\s+)?ok\s+(\d+)(.*)/) {
        my ($not, $n, $name) = (!! $1, $2, $3);
        $name =~ s/^\s*-\s*//;
        $self->refute( $not, $name );
        $self->{want_diag} = $not;
        $self->{order}++ if $n != $self->get_count;
    } elsif ($line =~ /^#+(.*)/) {
        $self->diag($1);
    } elsif ($line =~ /^1..(\d+)/) {
        # TODO disallow double plan, plan out of order
        $self->{plan} = $1;
    } elsif ($line =~ /^Bail out!(.*)/) {
        $self->bail_out($1);
    } elsif ($line =~ /^\s/) {
        # TODO subtest
    } else {
        carp "Can't recognize line $line";
    };
};

=head2 diag

Diag is turned off unless previous test failed.

=cut

sub diag {
    my $self = shift;
    $self->SUPER::diag(@_)
        if $self->{want_diag};
};

=head2 on_pass

Passed tests are omitted for great justice.

=cut

sub on_pass {
    return '';
};

=head2 eof

End a series of readlines. Some additional checks must be here,
but not done yet.

=cut

sub eof {
    my ($self) = @_;

    # generate other tests
    $self->done_testing;
};

=head2 get_passing

get_passing includes additional checks.

=cut

sub get_passing {
    my $self = shift;
    return $self->SUPER::get_passing
        && !$self->{order}
        && defined $self->{plan}
        ;
};

=head2 finish

Read the rest of the test fd.

=cut

sub finish {
    my $self = shift;

    my $fd = $self->{in};
    while (<$fd>) {
        $self->read_line($_);
    };
    $self->eof;
    return $self;
};

1;
