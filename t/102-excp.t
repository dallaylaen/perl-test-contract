#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;
use Test::Refute::Exception;

dies {
    die "foo";
} "foo", "Throws ok";

dies {
    die "foo";
} "bar", "Deliberately fail"; 

done_testing;

