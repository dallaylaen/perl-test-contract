package Test::Refute::Contract;

use strict;
use warnings;
our $VERSION = 0.0109;

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

use Test::Refute::Build qw(to_scalar);

our @EXPORT_OK = qw(contract);
our @CARP_NOT = qw(Test::Refute::Build Test::Refute);
# preload most basic tests
require Test::Refute::Basic;

=head1 OPTIONAL EXPORT

=head2 contract { CODE; };

=head2 contract { CODE; } $contract_instance;

Run a series of tests against a contract object, recording the output
for future analysis. See GETTERS below.

=cut

sub contract (&;$) { ## no critic # need block function
    my ($code, $engine) = @_;

    $engine ||= __PACKAGE__->new;
    $engine->start_testing;

    $code->();
    $engine->done_testing
        unless $engine->is_done;
    return $engine;
};

=head1 METHODS

The generalized object-oriented interface for C<Test::Refute> goes below.

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

    return $deny ? 0 : $self->{count}
        if $self->{skip_all};

    $self->{count}++;
    $message ||= "test $self->{count}";

    if ($deny) {
        $self->{fails}++;
        $self->on_fail( $message, $deny );
        $self->diag( Carp::shortmess( "Failed: $message" ));
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

=head2 plan( $n )

Commit to performing exactly n tests. This would die if testing had started.

=cut

sub plan {
    my ($self, $n) = @_;

    croak "plan(): argument must be numeric"
        unless $n =~ /^\d+$/;
    croak "plan(): testing already started"
        if $self->test_number;

    $self->{plan} = $n;
    return $self;
};

=head2 skip_all( "reason" )

reason must be true, or this won't work!

=cut

sub skip_all {
    my ($self, $reason) = @_;
    return if $self->is_done;
    $self->{skip_all} ||= $reason || 'unknown reason';
};

=head2 done_testing

Finalize test engine and remove it from the stack.

=cut

sub done_testing {
    my $self = shift;

    $self->{done} and croak "done_testing() called twice";

    if ($self->{plan} and !$self->{skip_all} and $self->{plan} != $self->test_number) {
        $self->refute(
            sprintf( "made %d/%d tests", $self->test_number, $self->{plan} )
            , "plan failed!"
        )
    };

    # engine cleanup MUST be called with true done flag.
    $self->{done}++;
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

=head2 get_plan

Returns number of planned tests, if given, or number of tests done if done.

B<EXPERIMENTAL> Logic is not obvious.

=cut

sub get_plan {
    my $self = shift;

    return $self->{plan} || ($self->is_done && $self->test_number);
};

=head2 is_skipped

=cut

sub is_skipped {
    my $self = shift;
    return $self->{skip_all} || '';
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

=head2 get_failed

Get failed tests as hash.

=cut

sub get_failed {
    my $self = shift;
    return $self->{failed};
};

=head2 get_tap

Get contract evaluation result as a multiline scalar.

May NOT be available in subclasses (dies in C<Test::Refute::TAP>).

=cut

sub get_tap {
    my ($self, $verbose) = @_;

    $verbose = 1 unless defined $verbose;
    $verbose++;
    return join "\n", grep { !/^#{$verbose}/ } @{ $self->{log} }, '';
};

=head1 SUBCLASS METHODS

Redefine these methods to get a custom contract behavior.

=cut

=head2 on_pass( $name )

What to do when test passes.

=cut

sub on_pass {
    my ($self, $name) = @_;

    $self->_log( join " ", "ok", $self->test_number, "-", $name );
    return;
};

=head2 on_fail ( $name, $details )

What to do when test fails.

=cut

sub on_fail {
    my ($self, $name, $cond) = @_;

    $self->{failed}{ $self->test_number } = [ $name, $cond ];
    $self->_log( join " ", "not ok", $self->test_number, "-", $name );
    return;
};

=head2 diag( $message )

Add a serious warning message.

The interface MAY change in the future in favour of @list.

=cut

sub diag {
    my ($self, @mess) = @_;

    #
    croak "diag(): Testing finished"
        if $self->is_done;
    $self->_log( join " ", "#", $_ )
        for split /\n+/, join "",
            map { defined $_ && !ref $_ ? $_ : to_scalar($_); } @mess;
    return;
};

=head2 note( $message )

Add a side note warning message.

The interface MAY change in the future in favour of @list.

=cut

sub note {
    my ($self, @mess) = @_;

    $self->_log( join " ", "##", $_ )
        for split /\n+/, join "",
            map { defined $_ && !ref $_ ? $_ : to_scalar($_); } @mess;
    return;
};

=head2 on_done

What to do when done_testing is called.

=cut

sub on_done {
    my $self = shift;

    my $comment = $self->{skip_all} ? (' # SKIP '.$self->{skip_all} ) : '';
    $self->_log( "1.." .$self->test_number . $comment );
};

=head2 bail_out( $reason )

What to do when bail_out is called.

The interface MAY change in the future.

=cut

sub bail_out {
    my ($self, $mess) = @_;

    $mess ||= '';
    $self->refute( "Bail out", $mess );
    $self->_log( "Bail out! $mess" );
    $self->{skip_all} = "Bail out! $mess";
    return;
};

sub _log {
    my ($self, $mess) = @_;

    $mess =~ s#\n+$##s;
    push @{ $self->{log} }, $mess;
};


1;
