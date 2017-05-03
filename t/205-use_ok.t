#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract::Unit q(no_plan);
use Test::Contract::Exception;

my $c = contract {
    local $INC{"No/Such/Module.pm"} = 1;
    no warnings 'once'; ## no critic
    local *No::Such::Module::import = sub { die "deliberately" };

    lives_ok {
        use_ok "Test::Contract::Unit";
    } "and live until the end";
    lives_ok {
        use_ok "No::Such::Module";
    } "but live until the end";
};
is $c->get_sign, "t1101d", "use_ok()";
note $c->get_tap;

done_testing;
