#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract::Unit q(no_plan);
use Test::Contract::Exception;

note contract {
    local $INC{"No/Such/Module.pm"} = 1;
    no warnings 'once'; ## no critic
    local *No::Such::Module::import = sub { die "deliberately" };

    lives_ok {
        use_ok "No::Such::Module", "fail deliberately";
    } "but live until the end";
}->sign("01", "use_ok")->get_tap;

done_testing;
