package Test::Refute::Contract::TAP::Reader;

use strict;
use warnings;
our $VERSION = 0.0103;

=head1 NAME

Test::Refute::Contract::TAP::Reader - test anything protocol parser for Test::Refute

=head1 DESCRIPTION

This module is a L<Test::Refute::Contract> that, instead of executing
tests, reads those from a TAP stream.

Additional tests are performed on the recieving end (ok's in order, plan
present etc).

=head1 METHODS

=cut

use Carp;
use parent qw(Test::Refute::Contract);

sub _NEWOPTIONS { __PACKAGE__->SUPER::_NEWOPTIONS, qw(in pid) };

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
        $self->{order}++ if $n != $self->test_number;
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

=head2 is_valid

is_valid includes additional checks.

=cut

sub is_valid {
    my $self = shift;
    return $self->SUPER::is_valid
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
