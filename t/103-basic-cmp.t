#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;
use Test::Refute::Exception;

note contract {
    cmp_ok 1, "<", 2;
    cmp_ok 2, "<", 1;
    cmp_ok "a", "lt", "b";
    cmp_ok "a", "gt", "b";
    cmp_ok undef, "eq", '';
    cmp_ok undef, "==", undef;
}->sign("101000")->get_tap;

dies {
    cmp_ok 1, "<<", 2;
} qr/cmp_ok.*Comparison.*<</;

done_testing;
