package Test::Refute::Basic::Is;

use strict;
use warnings;
our $VERSION = 0.0101;

=head1 NAME

Test::Refute::Basic::Is - most basic assertions for Test::Refute

=head1 DESCRIPTION

is() and is_contract() functions are crucial to bootstrapping L<Test::Refute>'s
own test suite, that's why these are put in a separate module.

You don't need it unless you are going to contribute to the core.

Please refer to L<Test::Refute> and L<Test::Refute::Contract>
that automatically load this module.

=cut

use Carp;
use parent qw(Exporter);
use Test::Refute::Build;

# Please update test description in Test::Refute::Basic
#     if you alter anything here.

# TODO to_scalar when it's available
build_refute is => sub {
    my ($got, $exp) = @_;

    if (defined $got xor defined $exp) {
        return "unexpected ". ((defined $got) ? "'$got'" : "undef value");
    };

    return '' if !defined $got or $got eq $exp;
    return "Got:      $got\nExpected: $exp";
}, args => 2, export => 1;

# Experimental still
# TODO This method is a joke yet
build_refute contract_is => sub {
    my ($c, $condition) = @_;

    # the happy case first
    my $not_ok = $c->get_failed;
    my @out = map { $not_ok->{$_} ? 0 : 1 } 1..$c->test_number;
    return '' if $condition eq join "", @out;

    # analyse what went wrong
    my @cond = split /.*?/, $condition;
    my @fail;
    push @fail, "Contract signature: @out";
    push @fail, "Expected:           @cond";
    push @fail, sprintf "Tests executed: %d of %d", scalar @out, scalar @cond
        if @out != @cond;
    for (my $i = 0; $i<@out && $i<@cond; $i++) {
        next if $out[$i] eq $cond[$i];
        push @fail, "Unexpected "
            .($not_ok->{$i} ? "not ok $i: $not_ok->{$i}" : "ok $i");
    };
    return join "\n", @fail;
}, args => 2, export => 1;

1;
