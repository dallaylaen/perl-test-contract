package Test::Refute::Engine;

use strict;
use warnings;
our $VERSION = 0.01;

use Carp;
use Scalar::Util qw(looks_like_number);
use parent qw(Exporter);

our @EXPORT_OK = qw(build_refute);

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

sub done_testing {
    my $self = shift;
    $self->{done}++ and croak "done_testing() called twice";
    $self->on_done;
    return $self;
};

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

sub is_valid {
    my $self = shift;
    return !$self->{fails};
};

sub errors {
    my $self = shift;
    return $self->{fails};
};

my %Backend;
my %Impl;

our $Default; # default engine - localizable
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
        $Default or croak("$name(): not currently testing anything");
        return $Default->$name( @_ );
    };

    $Backend{$name} = $opt{target};
    $Impl{$name}    = $cond;

    no strict 'refs';
    *{ $class."::$name" } = $method;
    if (! $opt{no_create} ) {
        *{ $opt{target}."::$name" } = $wrapper;
        push @{ $opt{target}."::EXPORT_OK" }, $name
            if $opt{export};
    };

    return 1;
};

sub get_impl {
    my ($class, $name) = @_;

    return $Impl{$name};
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
