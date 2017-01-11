#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract;
use Test::Contract::Exception;

my $out;
$out = contract {
    dies {
        die "foo";
    } "foo", "Dies ok";
}->get_tap(0);
is $out, "ok 1 - Dies ok\n1..1\n", "ok scenario";

$out = contract {
    dies {
        die "foo";
    } "bar", "Dies ok";
}->get_tap(0);
is $out, "not ok 1 - Dies ok\n1..1\n", "not ok scenario (wrong excp)";

$out = contract {
    lives_ok {
        die "foo";
    } "Lives ok";
}->get_tap(0);
is $out, "not ok 1 - Lives ok\n1..1\n", "lives_ok fail";

done_testing;

