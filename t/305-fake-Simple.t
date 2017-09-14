#!/usr/bin/env perl

use strict;
use warnings;

use Assert::Refute::Unit::Fake qw(more);

use Test::Simple;

die "FATAL: real Test::More loaded"
    if Test::Builder->can("ok");

ok 1;

done_testing;

