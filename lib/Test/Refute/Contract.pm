package Test::Refute::Contract;

use strict;
use warnings;
our $VERSION = 0.0104;

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

=cut

use Carp;
use Scalar::Util qw(looks_like_number);
use Exporter qw(import);

use Test::Refute::Build ();

our @EXPORT_OK = qw(contract);
# preload most basic tests
require Test::Refute::Basic;

=head1 OPTIONAL EXPORT

=head2 contract { CODE; };

=head2 contract { CODE; } $contract_instance;

Run a series of tests against a contract object, recording the output
for future analysis. See GETTERS below.

=cut

sub contract (&;$) {
    my ($code, $engine) = @_;

    $engine ||= __PACKAGE__->new;
    $engine->start_testing;

    $code->();
    $engine->done_testing;
    return $engine;
};

=head1 METHODS

=head2 new()

No options are currently being used. Just return an empty object.
This MAY change in the future.

=cut

sub new {
    my ($class, %opt) = @_;

    return bless {}, $class;
};

=head2 refute( $condition, $name )

If condition is false, return truth, also calling C<on_pass()> method.
If condition is true, complain loudly,
also calling c<on_fail()> and C<diag()> methods.

This is the CORE of the whole L<Test::Refure> suite.

The point of this semantics inversion (relative to a normal C<assert>)
is that when everything is fine, no further information is needed.
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

=head1 GETTERS

=head2 is_done

Return truth if testing is finished.

=cut

sub is_done {
    my $self = shift;

    return $self->{done};
};

=head2 test_number

Returns number of tests run so far

=cut

sub test_number {
    my $self = shift;
    return $self->{count} || 0;
};

=head2 is_valid

Returns truth if no tests failed so far.

=cut

sub is_valid {
    my $self = shift;
    return !$self->{fails};
};

=head2 error_count

Returns number of tests that failed.

=cut

sub error_count {
    my $self = shift;
    return $self->{fails} || 0;
};

=head1 SUBCLASS METHODS

=cut

sub on_pass {
    my ($self, $name) = @_;

    $self->_log( join " ", "ok", $self->test_number, "-", $name );
    return;
};

sub on_fail {
    my ($self, $name, $cond) = @_;

    $self->{failed}{ $self->test_number } = [ $name, $cond ];
    $self->_log( join " ", "not ok", $self->test_number, "-", $name );
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

    $self->_log( "1..".$self->test_number );
};

sub bail_out {
    my ($self, $mess) = @_;

    $self->{skip}++;
    $self->{failed}{ $self->test_number } = [ "Bail out", $mess ];
    $self->_log( "Bail out! $mess" );
    return;
};

sub _log {
    my ($self, $mess) = @_;

    $mess =~ s#\n+$##s;
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
