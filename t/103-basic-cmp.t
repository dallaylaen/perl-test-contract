#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract::Unit q(no_plan);
use Test::Contract::Exception;

my $c = contract {
    cmp_ok 1, "<", 2;
    cmp_ok 2, "<", 1;
    cmp_ok "a", "lt", "b";
    cmp_ok "a", "gt", "b";
    cmp_ok undef, "eq", '';
    cmp_ok undef, "==", undef;
};
is $c->get_sign, "t101000d";
note $c->get_tap;

dies {
    cmp_ok 1, "<<", 2;
} qr/cmp_ok.*Comparison.*<</;

done_testing;
