#!/usr/bin/env perl

use strict;
use Test::Refute;

use Test::Refute::Contract;

note contract {
    my $r = shift;
    can_ok 'Test::Refute', 'import';
    can_ok 'Test::Refute', 'no_such_method';
    can_ok $r, qw(is isnt ok like);
    can_ok $r, qr(foo bar);

    can_ok undef, "frobnicate";
    can_ok {}, "frobnicate";
}->sign("101000", "can_ok")->get_tap;

note contract {
    my $r = shift;

    isa_ok $r, "Test::Refute::Contract";
    isa_ok $r, "Test::Refute::TAP";

    isa_ok "Test::Refute::TAP", "Test::Refute::Contract";
    isa_ok "Test::Refute::Contract", "Test::Refute::TAP";

    isa_ok undef, "UNIVERSAL";
    isa_ok "", "UNIVERSAL";
}->sign("101000", "can_ok")->get_tap;

note contract {
    new_ok "Test::Refute::Contract";
    new_ok "Test::Refute::Contract", [], "Test::Refute";
    new_ok "No::Such::Class";
    new_ok undef;
}->sign("1000", "can_ok")->get_tap;

done_testing;
