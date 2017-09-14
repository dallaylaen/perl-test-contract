#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Unit;

my $test = contract {
    my $c = shift;
    $c->ok(1);
    die "Foobared";
};

not_ok $test->get_passing, "contract failed";
ok $test->get_done, "No more tests possible";
contract_is $test, "10", "1 passed, 1  failed";

done_testing;
