#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract::Unit q(no_plan);
use Test::Contract::Engine::TAP::Reader;

pipe( my $read, my $write )
    or do {
        plan skip_all => "pipe(1) failed: $!";
        exit 0;
    };

my $c = Test::Contract::Engine::TAP->new( out => $write );
my $tap = Test::Contract::Engine::TAP::Reader->new( in => $read );

$c->ok( 1, "fine" );
$c->refute( "reason", "not fine" );
$c->done_testing;
close( $write )
    or die "$!";

$tap->finish;
$tap->sign(10);

note $tap->get_tap;

done_testing;
