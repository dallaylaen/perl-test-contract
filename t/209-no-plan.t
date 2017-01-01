#!/usr/bin/env perl

use strict;
use warnings;
my @warn;
BEGIN {
    $SIG{__WARN__} = sub { push @warn, shift };
};

use Test::Refute 'no_plan';

note $warn[0];
like ($warn[0], "DEPRECATED.*".(quotemeta __FILE__).".*"
    , "deprecated warn referring to here");
is (scalar @warn, 1, "1 warning issued")
    or do {
        diag "WARNING: $_" for @warn;
    };
# done_testing(); skipped
