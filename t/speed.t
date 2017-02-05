#!/usr/bin/env perl

use strict;
use warnings;
my ($engine, $count) = @ARGV;

$engine ||= 'Test::Contract';
$count  ||= 1;

if ($engine eq 'print') {
    my $n = 0;
    *is = sub {
        my ($got, $exp, $mess) = @_;
        $n++;
        print( ($got eq $exp ? "" : "not ")."ok $n - $mess\n" );
    };
    *done_testing = sub { $n and print "1..$n\n" };
} else {
    my $fname = $engine;
    $fname =~ s#::#/#g;
    $fname .= ".pm";

    require $fname;
    $engine->import( 'no_plan' );
};

for (1 .. $count) {
    is (!($_ % 5) - !($_ % 7), 0, "Every 7th & 5th fail" );
};

done_testing();
