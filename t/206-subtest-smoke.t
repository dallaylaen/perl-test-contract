#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract;

ok (1, "pass");
subtest subt => sub {
    ok (1, "also pass");
};
ok (2, "pass again");

done_testing;
