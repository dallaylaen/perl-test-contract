#!/usr/bin/env perl

use strict;
use warnings;

use Test::Refute;
use Test::Refute::TAP;

sub contract_out (&);

my $content;

$content = contract_out {
    note "Foo";
};
is $content, "## Foo\n1..0\n", "note works";

$content = contract_out {
    diag "Foo";
};
is $content, "# Foo\n1..0\n", "diag works";

$content = contract_out {
    is (1, 1, "Equal");
};
is $content, "ok 1 - Equal\n1..1\n", "is happy path";

$content = contract_out {
    is (1, 0, "False");
};
$content =~ s/#.*?\n//gs;
is $content, "not ok 1 - False\n1..1\n", "is when it really isn't";

note "Some cmp_ok modes";

$content = contract_out {
    cmp_ok( 1, ">", 0, "more" );
    cmp_ok( 1, "<", 0, "no more" );
};
$content =~ s/#.*?\n//gs;
is $content, "ok 1 - more\nnot ok 2 - no more\n1..2\n", "cmp_ok";

done_testing;

sub contract_out(&) {
    my ($code) = @_;

    my $content = '';
    open my $fd, ">", \$content
        or die "Failed to redirect: $!";

    &contract( $code, Test::Refute::TAP->new( fd => $fd ) );
    return $content;
};
