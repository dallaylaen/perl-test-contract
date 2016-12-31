#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Test::Refute;

local $SIG{__WARN__} = \&Carp::confess; # TODO civilized Test::Warn or smth
my $c;

$c = contract {
    isnt undef, '', "isnt";
    isnt undef, undef, "2 undefs";
    isnt '', undef, "isnt";
    isnt 42, "foo", "isnt";
    isnt 42, 42, "numbers";
    isnt "foo", "foo", "string";
    isnt [], [], "diff structures";
    my $x = [];
    isnt $x, $x, "same stucture";
};

contract_is $c, "10110010";

done_testing;
