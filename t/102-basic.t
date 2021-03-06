#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Unit q(no_plan);

my $c;

$c = contract {
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
};
is $c->get_sign, "t1000110001d", "is()";
note $c->get_tap;

$c = contract {
    isnt 42, 137;
    isnt 42, 42;
    isnt undef, undef;
    isnt undef, 42;
    isnt 42, undef;
    isnt '', undef;
    isnt undef, '';
};
is $c->get_sign, "t1001111d", "isnt()";
note $c->get_tap;

$c = contract {
    like "foo", qr/oo*/;
    like "foo", "oo*";
    like "foo", qr/bar/;
    like "foo", "f.*o";
    like undef, qr/.*/;
};
is $c->get_sign, "t10010d", "like()";
note $c->get_tap;

$c = contract {
    unlike "foo", qr/bar/;
    unlike "foo", qr/foo/;
    unlike "foo", "oo*";
    unlike "foo", "f.*o";
    unlike undef, qr/.*/;
};
is $c->get_sign, "t10100d", "unlike()";
note $c->get_tap;

$c = contract {
    ok ok 1;
    ok ok 0;
    ok undef;
};
is $c->get_sign, "t11000d", "ok()";
note $c->get_tap;

$c = contract {
    not_ok 0;
    not_ok { foo => 42 };
};
is $c->get_sign, "t10d", "not_ok()";
note $c->get_tap;

$c = contract {
    isa_ok $_[0], "Assert::Refute";
    isa_ok $_[0], "Assert::Refute::Engine::TAP";
    isa_ok "Assert::Refute::Engine::TAP", "Assert::Refute";
    isa_ok "Assert::Refute", "Assert::Refute::Engine::TAP";
    isa_ok "Assert::Refute::Engine::TAP", "Assert::Refute::Engine::TAP";
    isa_ok "No::Such::Package", "Assert::Refute::Engine::TAP";
    isa_ok "Assert::Refute::Engine::TAP", "No::Such::Package";
    isa_ok "No::Such::Package", "No::Such::Package";
};
is $c->get_sign, "t10101000d", "isa_ok()";
note $c->get_tap;

$c = contract {
    can_ok $_[0], "can_ok";
    can_ok $_[0], "frobnicate";
    can_ok "Assert::Refute::Unit", "import", "can_ok";
    can_ok "Assert::Refute::Unit", "unknown_subroutine";
    can_ok "No::Exist", "can", "isa", "import";
};
is $c->get_sign, "t10100d", "can_ok()";
note $c->get_tap;

$c = contract {
    new_ok "Assert::Refute";
    new_ok "Assert::Refute", [indent => 1];
    new_ok "Assert::Refute", [indent => 1], "Assert::Refute::Engine::TAP";
    new_ok "Assert::Refute::Engine::TAP", [indent => 1], "Assert::Refute";
    new_ok "No::Such::Package";
    new_ok $_[0], [indent => 1];
    new_ok undef;
};
is $c->get_sign, "t1101010d", "new_ok()";
note $c->get_tap;

$c = contract {
    require_ok "Assert::Refute::Unit";
    require_ok "No::Such::Package::_______::000";
};
is $c->get_sign, "t10d", "require_ok()";
note $c->get_tap;

done_testing;
