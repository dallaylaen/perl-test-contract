#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;

my $c = contract {
    is (42, 42, "Life is life");
    is (42, 137, "Life is fine");
};

ok( $c->is_done, "Contract done" );

diag $c->get_tap;

done_testing;
