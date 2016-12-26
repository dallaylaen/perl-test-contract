#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;

is 42, 42, "is happy path";
is 42, 43, "deliberate error";
is 42, 44, "deliberate error";

done_testing;

