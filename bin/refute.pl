#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use Getopt::Long;
use File::Basename qw(basename dirname);

# Always use latest & greatest lib, if available
use lib dirname(__FILE__)."/../lib";
use Test::Refute;
use Test::Refute::Contract;
use Test::Refute::Contract::TAP::Reader;

my $all = Test::Refute::TAP->new->start_testing;

my @inc;
GetOptions (
    "I=s" => \@inc,
) or die "Bad options. See $0 --help";

my @plopt;
push @plopt, map { "-I$_" } @inc;

my @files;
find( sub {
    -f $_ and /\.t$/ and push @files, $File::Find::name;
}, @ARGV);

@files = sort @files;

foreach my $f (@files) {
    my @localopt;
    open (my $peek, "<", $f)
        or die "Failed to open $f: $!";
    my $line = <$peek>;
    $line =~ /\s-T\b/ and push @localopt, "-T";
    close $peek;

    my $pid = open (my $fd, "-|", perl => @plopt => @localopt => $f)
        or do {
            ok 0, $f;
            diag $!;
            next;
        };

    my $tap = Test::Refute::Contract::TAP::Reader->new( in => $fd, pid => $pid );
    # TODO parallel??
    $tap->finish;
    not_ok $tap->get_failed && $tap, $f;
};

my $failed = $all->get_failed;

if ($failed) {
    # print cumulative error summary
    my @bad = sort { $a->[0] <=> $b->[0] } values %$failed;

    foreach my $t (@bad) {
        print "not ok $t->[0]\n";
        print $t->[1]->get_tap;
    };
    print "RESULT: FAIL\n";
} else {
    print "RESULT: PASS\n";
};

exit !$all->is_valid;



