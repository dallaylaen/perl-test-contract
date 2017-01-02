#!/usr/bin/env perl

use strict;
use warnings;
use Test::Refute;
use Test::Refute::Contract::TAP::Reader;

pipe( my $read, my $write )
    or do {
        plan skip_all => "pipe(1) failed: $!";
        exit 0;
    };

my $c = Test::Refute::TAP->new( out => $write );
my $tap = Test::Refute::Contract::TAP::Reader->new( in => $read );

$c->ok( 1, "fine" );
$c->refute( "reason", "not fine" );
$c->done_testing;
close( $write );

$tap->finish;
$tap->sign(10);

note $tap->get_tap;

done_testing;
