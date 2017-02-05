#!/usr/bin/env perl

use strict;
use warnings;

my $bin;
BEGIN {
    $bin = __FILE__;
    $bin =~ s#/*[^/]+$##;
    $bin ||= '.';
    unshift @INC, "$bin/../fake_lib", "$bin/../lib";
};

use Test::Simple;
die "FATAL: real Test::More loaded"
    if Test::Builder->can("ok");

ok 1;

done_testing();

