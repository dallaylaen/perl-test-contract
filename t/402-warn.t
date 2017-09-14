#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Unit;
use Assert::Refute::Warn;

my $c;

$c = contract {
    warns_like {
        warn "Foo";
        warn "Bar";
    } ["Foo", qr/Ba/], "all ok";
};

contract_is $c, "1", "warnings ok";
note $c->get_tap;

$c = contract {
    warns_like {
        warn "Foo";
    } ["Foo", qr/Ba/], "all ok";
};

contract_is $c, "0", "warnings count mismatch";
note $c->get_tap;

$c = contract {
    warns_like {
        warn "Bar";
        warn "Foo";
    } ["Foo", qr/Ba/], "all ok";
};

contract_is $c, "0", "warnings bad order";
note $c->get_tap;

done_testing;
