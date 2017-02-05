#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract q(no_plan);

use Test::Contract::Deep;

*to_scalar = \&Test::Contract::Deep::to_scalar;
note "TESTING to_scalar()";

is to_scalar(undef), "(undef)", "to_scalar undef";
is to_scalar(-42.137), -42.137, "to_scalar number";
is to_scalar("foo bar"), '"foo bar"', "to_scalar string";
is to_scalar("\t\0\n\"\\"), '"\\t\\0\\n\\"\\\\"', "to_scalar escape";

like to_scalar( Test::Contract::Engine->new )
    , "Test::Contract::Engine\\{.*\\}"
    , "to_scalar blessed";

like to_scalar( Test::Contract::Engine->new, 0 )
    , "Test::Contract::Engine/[a-f0-9]+"
    , "to_scalar blessed shallow";

is to_scalar( [] ), "[]", "to_scalar empty array";
is to_scalar( {} ), "{}", "to_scalar empty hash";

is to_scalar( [foo => 42] ), "[\"foo\", 42]", "array with scalars";
is to_scalar( {foo => 42} ), "{\"foo\":42}", "hash with scalars";

note "TESTING deep_diff() negative";
*deep_diff = \&Test::Contract::Deep::deep_diff;

is deep_diff( undef, undef), '', "deep_diff undef";
is deep_diff( 42, 42 ), '', "deep_diff equal";
is deep_diff( [ foo => 42 ], [ foo => 42 ] ), '', "deep_diff array";
is deep_diff( { foo => 42 }, { foo => 42 } ), '', "deep_diff hash";

note "TESTING deep_diff() positive";
is deep_diff( { foo => { bar => 42 } }, { foo => { baz => 42 } } )
    , '{"foo":{"bar":42!=(none), "baz":(none)!=42}}'
    , "deep_diff diff!";

is deep_diff(
        { foo => [], bar => { baz => [1,2,3] } },
        { foo => {}, bar => { baz => [ 1,2 ] } },
    ), '{"bar":{"baz":[2:3!=(undef)]}, "foo":[]!={}}'
    , "Harder structure";

is_deeply {foo=>42}, {foo=>42}, "smoke the sub";

done_testing;
