#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Assert::Refute::Engine::More;

ok (1, "test 1");
my $c = Assert::Refute::Engine::More->new;

$c->ok( 2, "test 2" );

ok (3, "test 3");

$c->ok( 4, "test 4" );

done_testing;
