#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;

my $c = contract {
    contract {
        ok 1;
        ok 0;
        ok 1;
    }->sign("000")->sign("101")->sign("1010")->sign("1");
};

contract_is ( $c, "0100", "Contract fulfilled in 1 case of 4" );

done_testing;
