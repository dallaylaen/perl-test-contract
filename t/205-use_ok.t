#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;
use Test::Refute::Exception;

my $c = contract {
    local $INC{"No/Such/Module.pm"} = 1;
    no warnings 'once'; ## no critic
    local *No::Such::Module::import = sub { die "deliberately" };

    lives_ok {
        use_ok "No::Such::Module", "fail deliberately";
    } "but live until the end";
};

is $c->error_count, 1, "Test failed";
is $c->test_number, 2, "2 tests total";

note $c->get_tap;

done_testing;
