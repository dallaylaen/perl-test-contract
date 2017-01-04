#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;

note contract {
    is 42, 42;
    is 42, 137;
    is undef, '';
    is '', undef;
    is undef, undef;
    is "foo", "foo";
    is "foo", "bar";
    is {}, [];
    is {}, {}, "different struct";
    my @x = 1..5;
    my @y = 11..15;
    is @x, @y, "scalar context";
}->sign("1000110001", "is()")->get_tap;

note contract {
    isnt 42, 137;
    isnt 42, 42;
    isnt undef, undef;
    isnt undef, 42;
    isnt 42, undef;
    isnt '', undef;
    isnt undef, '';
}->sign("1001111", "isnt()")->get_tap;

note contract {
    like "foo", qr/oo*/;
    like "foo", "oo*";
    like "foo", qr/bar/;
    like "foo", "f.*o";
    like undef, qr/.*/;
}->sign("10010", "like()")->get_tap;

note contract {
    unlike "foo", qr/bar/;
    unlike "foo", qr/foo/;
    unlike "foo", "oo*";
    unlike "foo", "f.*o";
    unlike undef, qr/.*/;
}->sign("10100", "unlike()")->get_tap;

note contract {
    ok ok 1;
    ok ok 0;
    ok undef;
}->sign("11000", "ok()")->get_tap;

note contract {
    not_ok 0;
    not_ok { foo => 42 };
}->sign("10", "not_ok()")->get_tap;

note contract {
    isa_ok $_[0], "Test::Refute::Contract";
    isa_ok $_[0], "Test::Refute::TAP";
    isa_ok "Test::Refute::TAP", "Test::Refute::Contract";
    isa_ok "Test::Refute::Contract", "Test::Refute::TAP";
    isa_ok "Test::Refute::TAP", "Test::Refute::TAP";
    isa_ok "No::Such::Package", "Test::Refute::TAP";
    isa_ok "Test::Refute::TAP", "No::Such::Package";
    isa_ok "No::Such::Package", "No::Such::Package";
}->sign("10101000", "isa_ok()")->get_tap;

note contract {
    can_ok $_[0], "can_ok";
    can_ok $_[0], "frobnicate";
    can_ok "Test::Refute", "import", "can_ok";
    can_ok "Test::Refute", "unknown_subroutine";
    can_ok "No::Exist", "can", "isa", "import";
}->sign("10100", "can_ok()")->get_tap;

note contract {
    new_ok "Test::Refute::Contract";
    new_ok "Test::Refute::Contract", [indent => 1];
    new_ok "Test::Refute::Contract", [indent => 1], "Test::Refute::TAP";
    new_ok "Test::Refute::TAP", [indent => 1], "Test::Refute::Contract";
    new_ok "No::Such::Package";
    new_ok $_[0], [indent => 1];
    new_ok undef;
}->sign("1101010", "new_ok()")->get_tap;

note contract {
    require_ok "Test::Refute";
    require_ok "No::Such::Package::_______::000";
}->sign("10", "require_ok")->get_tap;

done_testing;
