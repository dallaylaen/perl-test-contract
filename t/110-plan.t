#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Unit q(no_plan);

my $c;
$c = contract {
    plan skip_all => "Foobared";
    is (42, 137, "Should be ignored");
};
ok( $c->get_passing, "Valid contract" );
is $c->get_count, 0, "no tests executed";

$c = contract {
    plan tests => 3;
    ok (1, "well");
};
ok !$c->get_passing, "Bad contract";
is $c->get_count, 2, "extra failed test";
is $c->get_error_count, 1, "extra failed test";

$c = contract {
    ok (1, "well");
    bail_out "foobared";
    ok (2, "well 2");
};
ok !$c->get_passing, "Bailed out = fail";
like $c->get_tap, qr/.*\nBail out! foobared\n.*/s, "tap contains bail_out";

done_testing;
