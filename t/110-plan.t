#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;

my $c;
$c = contract {
    plan skip_all => "Foobared";
    is (42, 137, "Should be ignored");
};
ok( $c->is_valid, "Valid contract" );
is $c->test_number, 0, "no tests executed";

$c = contract {
    plan tests => 3;
    ok (1, "well");
};
ok !$c->is_valid, "Bad contract";
is $c->test_number, 2, "extra failed test";
is $c->error_count, 1, "extra failed test";

$c = contract {
    ok (1, "well");
    bail_out "foobared";
    ok (2, "well 2");
};
ok !$c->is_valid, "Bailed out = fail";
like $c->get_tap, qr/.*\nBail out! foobared\n.*/s, "tap contains bail_out";

done_testing;
