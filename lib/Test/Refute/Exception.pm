package Test::Refute::Exception;

use strict;
use warnings;
our $VERSION = 0.0104;

=head1 NAME

Test::Refute::Exception - eval/die related plugin for Test::Refute

=head1 DESCRIPTION

Check that code either dies with a specific message, or lives through
given code block.

See also L<Test::Exception>. This one is MUCH simpler.

See L<Test::Refute> for the general rules regarding tests, contracts, etc.

=head1 SYNOPSIS

    use Test::Refute;
    use Test::Exception;

    use My::Module;

    lives_ok {
        My::Module->safe;
    }, "the code doesn't die";

    dies {
        My::Module->unsafe;
    }, qr(My::Module), "the code dies as expected";

    done_testing;

=head1 FUCTIONS

All functions below are exported by default.

=cut

use Carp;
use parent qw(Exporter);
our @EXPORT = qw(dies lives_ok);

use Test::Refute::Build qw(build_refute refute_engine);

=head2 dies { CODE; } qr/.../, "name";

Check that code dies, and exception matches the regex specified.

=cut

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

sub dies (&@) { ## no critic # need block function
    refute_engine->dies(@_);
};

=head2 lives_ok { CODE; } "name";

Check that code lives through given code block.

=cut

build_refute lives_ok => sub {
    my $code = shift;

    croak "lives_ok: 1st argument must be a function or code block"
        unless ref $code eq 'CODE';

    eval { $code->(); 1 } and return 0;
    return "Code dies unexpectedly: ".($@ || "(unknown error)");
}, args => 1, no_create => 1;

sub lives_ok (&@) { ## no critic # need block function
    refute_engine->lives_ok(@_);
};

1;
