package Test::Refute::Contract;

use strict;
use warnings;
our $VERSION = 0.0101;

=head1 NAME

Test::Refute::Contract - apply a series of tests/assertions within an application/module

=head1 SYNOPSIS

    package My::Module;
    use Test::Refute::Contract;

    sub my_method {
        my $user_data = shift;

        my $contract = Test::Refute::Contract->new;
        $contract->is( $user_data->answer, 42, "Life and everything" );
        $contract->done_testing;
        if ($contract->is_valid) {
            ...
        };
    };

=head1 METHODS

=cut

use Carp;
use parent qw(Test::Refute::Engine);

sub on_pass {
    my ($self, $name) = @_;

    $self->_log( join " ", "ok", $self->current_test, "-", $name );
    return 1;
};

sub on_fail {
    my ($self, $name, $cond) = @_;

    $self->{failed}{ $self->current_test } = [ $name, $cond ];
    $self->_log( join " ", "not ok", $self->current_test, "-", $name );
    return 1;
};

sub diag {
    my ($self, $mess) = @_;

    # 
    croak "diag(): Testing finished"
        if $self->is_done;
    $self->_log( join " ", "#", $_ )
        for split /\n+/, $mess;
    return $self;
};

sub note {}; # TODO

sub on_done {
    my $self = shift;

    $self->_log( "1..".$self->current_test );
};

sub _log {
    my ($self, $mess) = @_;

    push @{ $self->{log} }, $mess;
};

sub get_tap {
    my $self = shift;
    return join "\n", @{ $self->{log} };
};

sub get_failed {
    my $self = shift;
    return $self->{failed};
};
1;
