#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract::Unit q(no_plan);

note contract {
    my $c = shift;
    $c->ok(1);
    $c->ok(0);
    $c->ok(1);
}->sign(101)->get_tap;

done_testing;
