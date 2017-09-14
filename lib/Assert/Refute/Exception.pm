package Assert::Refute::Exception;

use strict;
use warnings;
our $VERSION = 0.0302;

=head1 NAME

Assert::Refute::Exception - eval/die related plugin for Assert::Refute

=head1 DESCRIPTION

Check that code either dies with a specific message, or lives through
given code block.

See also L<Test::Exception>. This one is MUCH simpler.

See L<Assert::Refute> for the general rules regarding tests, contracts, etc.

=head1 SYNOPSIS

    use Assert::Refute;
    use Test::Exception;

    use My::Module;

    lives_ok {
        My::Module->safe;
    }, "the code doesn't die";

    dies_like {
        My::Module->unsafe;
    }, qr(My::Module), "the code dies as expected";

    done_testing;

=head1 FUCTIONS

All functions below are exported by default.

=cut

use Carp;
use Exporter qw(import);

use Assert::Refute::Engine::Build qw(build_refute contract_engine);

=head2 dies_like { CODE; } qr/.../, "name";

Check that code dies, and exception matches the regex specified.

=cut

build_refute dies_like => sub {
    my ($code, $expr) = @_;

    croak "dies: 1st argument must be a function or code block"
        unless ref $code eq 'CODE';
    $expr =~ qr/$expr/
        unless ref $expr eq 'Regexp';

    eval { $code->(); 1 }
        and return "Code block lives unexpectedly";
    return 0 if $@ =~ $expr;

    return "Got: $@\nExpected: $expr\n ";
}, block => 1, args => 1, export => 1;

=head2 lives_ok { CODE; } "name";

Check that code lives through given code block.

=cut

build_refute lives_ok => sub {
    my $code = shift;

    croak "lives_ok: 1st argument must be a function or code block"
        unless ref $code eq 'CODE';

    eval { $code->(); 1 } and return 0;
    return "Code dies unexpectedly: ".($@ || "(unknown error)");
}, block => 1, args => 0, export => 1;

1;
