package Test::Refute::Contract;

use strict;
use warnings;
our $VERSION = 0.0103;

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
use Scalar::Util qw(looks_like_number);

use Test::Refute::Build ();

# preload most basic tests
require Test::Refute::Basic;

=head2 new()

No options are currently being used. Just return an empty object.
This MAY change in the future.

=cut

sub new {
    my ($class, %opt) = @_;

    return bless {}, $class;
};

=head2 refute( $condition, $name )

If condition is false, return truth (using on_pass method).
If condition is true, complain loudly (using on_fail and diag methods).

The whole point of this inversion (relative to a normal assert) is
that when everything is fine, no further information is needed.
However, when things do not work well, details may be helpful.

=cut

# TODO or should we swap args?
sub refute {
    my ($self, $deny, $message) = @_;

    croak "Already done testing"
        if $self->{done};

    $self->{count}++;
    $message ||= "test $self->{count}";

    if ($deny) {
        $self->{fails}++;
        $self->on_fail( $message, $deny );
        $self->diag( $deny )
            unless looks_like_number($deny);
        return 0;
    };

    $self->on_pass( $message );
    return $self->{count};
};

sub current_test {
    my $self = shift;
    return $self->{count} || 0;
};

=head2 start_testing

Push this engine onto the stack. All prototyped checks
will now be redirected to it.

=cut

sub start_testing {
    my $self = shift;

    $self->{count} and croak "start_testing() called after tests";
    Test::Refute::Build::refute_engine_push( $self );

    return $self;
};

=head2 done_testing

Finalize test engine and remove it from the stack.

=cut

sub done_testing {
    my $self = shift;

    $self->{done}++ and croak "done_testing() called twice";
    Test::Refute::Build::refute_engine_cleanup();

    $self->on_done;

    return $self;
};

sub DESTROY {
    Test::Refute::Build::refute_engine_cleanup();
};

sub is_done {
    my $self = shift;

    return $self->{done};
};

sub is_valid {
    my $self = shift;
    return !$self->{fails};
};

sub error_count {
    my $self = shift;
    return $self->{fails} || 0;
};

=head1 SUBCLASS METHODS

=cut

sub on_pass {
    my ($self, $name) = @_;

    $self->_log( join " ", "ok", $self->current_test, "-", $name );
    return;
};

sub on_fail {
    my ($self, $name, $cond) = @_;

    $self->{failed}{ $self->current_test } = [ $name, $cond ];
    $self->_log( join " ", "not ok", $self->current_test, "-", $name );
    return;
};

sub diag {
    my ($self, $mess) = @_;

    # 
    croak "diag(): Testing finished"
        if $self->is_done;
    $self->_log( join " ", "#", $_ )
        for split /\n+/, $mess;
    return;
};

sub note {
    my ($self, $mess) = @_;

    $self->_log( join " ", "##", $_ )
        for split /\n+/, $mess;
    return;
};

sub on_done {
    my $self = shift;

    $self->_log( "1..".$self->current_test );
};

sub _log {
    my ($self, $mess) = @_;

    push @{ $self->{log} }, $mess;
};

sub get_tap {
    my ($self, $verbose) = @_;

    $verbose = 1 unless defined $verbose;
    $verbose++;
    return join "\n", grep { !/^#{$verbose}/ } @{ $self->{log} }, '';
};

sub get_failed {
    my $self = shift;
    return $self->{failed};
};

1;
