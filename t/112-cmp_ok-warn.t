#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Unit;
use Assert::Refute::Warn;

warns_like {
    contract_is contract {
        cmp_ok '1e1', '<', '1e2';
        cmp_ok undef, '<', "foo";
        cmp_ok '', '<', 5;
        cmp_ok '0 but true', '<', 5;
    }, '1001', "Non-numerics all fail for good";
} [], "No warnings for non-numerics in cmp";

done_testing;

