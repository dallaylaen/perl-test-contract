#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;

my $count = shift || 0;

ok (1);

for (1 .. $count) {
    is (int(rand() * 1.1), 0, "Random fail" );
};

done_testing;
