package Test::Refute::Exception;

use strict;
use warnings;
our $VERSION = 0.0103;

use Carp;
use parent qw(Exporter);
our @EXPORT = qw(dies lives_ok);

use Test::Refute::Build qw(build_refute refute_engine);

build_refute dies => sub {
    my ($code, $expr) = @_;

    $expr =~ qr/$expr/
        unless ref $expr eq 'Regexp';
    croak "dies: 1st argument must be a function or code block"
        unless ref $code eq 'CODE';

    eval { $code->() };
    return 0 if $@ =~ $expr;

    return "Code block lives"
        unless $@;

    return "Got: $@\nExpected: $expr\n ";
}, args => 2, no_create => 1;

sub dies (&@) {
    refute_engine->dies(@_);
};

build_refute lives_ok => sub {
    my $code = shift;

    croak "lives_ok: 1st argument must be a function or code block"
        unless ref $code eq 'CODE';

    eval { $code->(); 1 } and return 0;
    return "Code dies unexpectedly: ".($@ || "(unknown error)");
}, args => 1, no_create => 1;

sub lives_ok (&@) {
    refute_engine->lives_ok(@_);
};

1;
