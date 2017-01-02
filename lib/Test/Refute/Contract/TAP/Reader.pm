package Test::Refute::Contract::TAP::Reader;

use strict;
use warnings;
our $VERSION = 0.0101;

=head1 NAME

Test::Refute::Contract::TAP::Reader - test anything protocol parser for Test::Refute

=head1 DESCRIPTION

This module is a L<Test::Refute::Contract> that, instead of executing
tests, reads those from a TAP stream.

Additional tests are performed on the recieving end (ok's in order, plan
present etc).

=head1 METHODS

=cut

use parent qw(Test::Refute::Contract);

sub _NEWOPTIONS { __PACKAGE__->SUPER::_NEWOPTIONS, qw(in pid) };

# parse?
sub read_line {
    my ($self, $line) = @_;

    chomp $line;
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
        warn "Can't recognize line $line";
    };
};

sub diag {
    my $self = shift;
    $self->SUPER::diag(@_)
        if $self->{want_diag};
};

sub on_pass {
    return '';
};

sub eof {
    my ($self) = @_;

    # generate other tests
    $self->done_testing;
};

sub is_valid {
    my $self = shift;
    return $self->SUPER::is_valid
        && !$self->{order}
        ;
};

sub run_command {
    my ($self, $cmd) = @_;

    $self->{pid} = open (my $fd, "-|", $cmd)
        or die "Failed to start $cmd: $!";

    $self->{in} = $fd;
};

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
