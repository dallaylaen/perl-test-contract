#!/usr/bin/env perl

use strict;
use warnings;
my ($engine, $count) = @ARGV;

$engine ||= 'Test::Refute';
$count  ||= 0;

my $fname = $engine;
$fname =~ s#::#/#g;
$fname .= ".pm";

require $fname;
$engine->import();

ok (1);

for (1 .. $count) {
    is (int(rand() * 1.1), 0, "Random fail" );
};

done_testing();
