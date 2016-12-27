package Test::Refute::Engine;

use strict;
use warnings;
our $VERSION = 0.0101;

=head1 NAME

Test::Refute::Engine - a toolkit for building Test::Refute tests

=head1 DESCRIPTION

This module allows to extend Test::Refute suite.

=head1 SYNOPSIS

Adding your own tests:

    package My::Test;

    use strict;
    use warnings;
    use parent qw(Exporter);
    use Test::Refute::Engine qw(build_refute);

    build_refute long_enough => sub {
        my ($str, $len) = @_;
        return 0 if length $str > $len;
        return "Got: $str\nExpected: at least $len chars";
    }, args => 2, export => 1;

    1;

    # in another file
    use Test::Refute;
    use My::Test;

    long_enough( foo    => 5, "Foo is not long enough" );
    long_enough( foobar => 5, "But foobar is" );

    done_testing;

Creating more test engines:

    package My::Engine;
    use strict;
    use warnings;
    use parent qw(Test::Refute::Engine);

    sub diag {
        ...
    };
    sub note {
        ...
    };
    sub on_pass {
        ...
    };
    sub on_fail {
        ...
    };

    1;

    # Elsewhere

    use strict;
    use warnings;
    use My::Engine;

    # inside a sub ...
    sub {
        my %input = @_;
        my $contract = My::Engine->new;

        $contract->is ($input{answer}, 42, "Answer is always 42" );
        $contract->like ($input{date}, '\d+-\d\d?-\d\d?', "Date looks like a date" );

        if ($contract->is_valid) {
            ...
        };
    };

The two can be combined, i.e. requiring My::Test somewhere will make
long_enough available to all Engine's descendants.

=head1 EXPORTS

Both build_refute and refute_engine are optional exports.

=cut

use Carp;
use Scalar::Util qw(looks_like_number);
use parent qw(Exporter);

our @EXPORT_OK = qw(build_refute refute_engine);

=head2 build_refute

=cut

my %Backend;

sub build_refute(@) {
    my ($name, $cond, %opt) = @_;

    my $class = __PACKAGE__;

    if (my $backend = ( $class->can($name) ? $class : $Backend{$name} ) ) {
        croak "build_refute(): '$name' already registered by $backend";
    };

    $opt{target} ||= caller;

    my $nargs = $opt{args} || 0;

    my $method  = sub {
        my $self = shift;
        my $message = pop unless @_ <= $nargs;

        return $self->refute( $cond->(@_), $message );
    };
    my $wrapper = sub {
        return refute_engine()->$name( @_ );
    };

    $Backend{$name} = $opt{target};

    no strict 'refs';
    *{ $class."::$name" } = $method;
    if (! $opt{no_create} ) {
        *{ $opt{target}."::$name" } = $wrapper;
        push @{ $opt{target}."::EXPORT_OK" }, $name
            if $opt{export};
    };

    return 1;
};

=head2 refute_engine

Returns current default engine, dies if none right now.

=cut

my @stack;

sub refute_engine() {
    @stack or croak [caller]->[3]."(): Not currently testing anything";
    return $stack[-1];
};

=head1 OBJECT-ORIENTED INTERFACE

OO interface allows to build contracts, subtests, customizable asserts etc.

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

=head2 start_testing

Push this engine onto the stack. All prototyped checks
will now be redirected to it.

=cut

sub start_testing {
    my $self = shift;

    $self->{count} and croak "start_testing() called after tests";
    push @stack, $self;

    return $self;
};

=head2 done_testing

Finalize test engine and remove it from the stack.

=cut

sub done_testing {
    my $self = shift;

    $self->{done}++ and croak "done_testing() called twice";

    # Some overengineered trash to make subtests and tests of suite itself work
    while (@stack and $stack[-1]->is_done) {
        pop @stack;
    };

    $self->on_done;

    return $self;
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

=head1 METHODS TO IMPLEMENT

=cut

sub on_pass {
    croak "on_pass(): Unimplemented";
};
sub on_fail {
    croak "on_fail(): Unimplemented";
};
sub diag {
    croak "diag(): Unimplemented";
};
sub note {
    croak "note(): Unimplemented";
};
sub on_done {
    croak "on_done(): Unimplemented";
};

# build basic stuff
our @Basic;

push @Basic, 'is';
build_refute is => sub {
    my ($got, $exp) = @_;

    return '' if $got eq $exp;
    return "Got:      $got\nExpected: $exp";
}, args => 2, no_create => 1;

push @Basic, 'ok';
build_refute ok => sub {
    my $got = shift;

    return !$got;
}, args => 1, no_create => 1;

push @Basic, 'use_ok';
build_refute use_ok => sub {
    my $mod = shift;
    my $file = $mod;
    $file =~ s#::#/#g;
    $file .= ".pm";
    eval { require $file; $mod->import; 1 } and return '';
    return $@ || "Failed to load $mod";
}, args => 1, no_create => 1;

1;
