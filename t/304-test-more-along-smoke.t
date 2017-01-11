#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Contract::Engine::More;

ok (1, "test 1");
my $c = Test::Contract::Engine::More->new;

$c->ok( 2, "test 2" );

ok (3, "test 3");

$c->ok( 4, "test 4" );

done_testing;
