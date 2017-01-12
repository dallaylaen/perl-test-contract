#!/usr/bin/env perl

use strict;
use warnings;

require Test::Contract;
my $main = Test::Contract::Engine::TAP->new;

# At this point, real stdout is saved inside $main, so we can dispose of it
$| = 1;
pipe my $read, my $write
    or die "pipe failed: $!";
open STDOUT, ">&", $write
    or die "Redirect failed: $!";

my $default;
do {
    Test::Contract->import;
    $default = Test::Contract->get_engine;
    ok(1);
    Test::Contract->reset;
    done_testing();
};

close $write;

sysread $read, my $output, 4096
    or die "failed to read self pipe: $!";

$main->is( $output, "ok 1\n", "done_testing was not seen" );
$main->ok( $default->get_done, "but it WAS executed" );
$main->is( $default->get_skipped, "reset called", "Skip recorded" );
$main->done_testing;
exit !$main->get_passing;
