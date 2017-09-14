#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Unit q(no_plan);
use Assert::Refute::Engine::TAP::Reader;

pipe( my $read, my $write )
    or do {
        plan skip_all => "pipe(1) failed: $!";
        exit 0;
    };

my $c = Assert::Refute::Engine::TAP->new( out => $write );
my $tap = Assert::Refute::Engine::TAP::Reader->new( in => $read );

$c->ok( 1, "fine" );
$c->refute( "reason", "not fine" );
$c->done_testing;
close( $write )
    or die "$!";

$tap->finish;
is $tap->get_sign, "t10d", "signature as expected";

note $tap->get_tap;

done_testing;
