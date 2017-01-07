#!/usr/bin/env perl

package Test::Refute::bin; # avoid polluting main

use strict;
use warnings;
use File::Find;
use Getopt::Long;
use File::Basename qw(basename dirname);

# Always use latest & greatest lib, if available
use lib dirname(__FILE__)."/../lib";
use Test::Refute qw(no_init);
use Test::Refute::Contract;
use Test::Refute::Contract::TAP::Reader;

my $all = Test::Refute::TAP->new->start_testing;

# make Getopt work with Perl-ish notation
@ARGV = map { /(-[IMm])(.*)/ ? ($1, $2) : $_ } @ARGV;

my @inc;
my @fake;
my @preload;
GetOptions (
    "I=s" => \@inc,
    "help" => \&usage,
    "preload=s" => \@preload,
    "faketest" => sub { @fake = ( dirname(__FILE__)."/../fake_lib"); },
) or die "Bad options. See $0 --help";

sub usage {
    print <<"HELP";
$0 [options] [test_dir] ...
- A TAP-based test suite runner
Options may include:
    -I - add a library path
    --preload Module::Name,Other::Module... - experimental module caching mode
    --faketest (EXPERIMENTAL) - use Test::Refute in place of Test::More
    --help - this message
This is ALPHA software, use prove(1) when in doubt.
HELP
    exit 0;
};

my @plopt;
push @plopt, map { "-I$_" } @fake, @inc;
@preload = split /,/,join ",", @preload;

my @files;
find( sub {
    -f $_ and /\.t$/ and push @files, $File::Find::name;
}, @ARGV);

@files = sort @files;

if (@preload) {
    unshift @INC, @fake, @inc;

    package main;

    foreach my $mod( @preload ) {
        my $fname = $mod;
        $fname =~ s#::#/#g;
        $fname .= ".pm" unless $fname =~ /\.p[lm]$/;
        require $fname;
        warn "Preloaded $mod from $INC{$fname}\n";
    };
};

foreach my $f (@files) {
    my $tap = get_reader( $f );
    # TODO parallel??
    $tap->finish;
    not_ok !$tap->get_passed && $tap, $f;
};

my $failed = $all->get_failed;

if ($failed) {
    # print cumulative error summary
    my @bad = sort { $a->[0] cmp $b->[0] } values %$failed;

    foreach my $t (@bad) {
        print "not ok $t->[0]\n";
        print $t->[1]->get_tap(2);
    };
    print "RESULT: FAIL\n";
} else {
    print "RESULT: PASS\n";
};

exit !$all->get_passed;

# TODO move this into TAP::Reader after all
sub get_reader {
    my $f = shift;

    my ($in, $pid);

    if (@preload) {
        return Test::Refute::Contract::TAP::Reader->new (
            indent => 1, replace_stdout => 1, eval => sub {
                $0 = $f;
                @ARGV = ();

                eval {
                    package main;
                    do $f;
                    die $@ if $@;
                    1;
                } or do {
                    not_ok $@ || $! || 1, "died";
                    exit 1;
                };
                exit 0;
            } );
        # end callback && end if (preload)
    } else {
        my @localopt;
        open (my $peek, "<", $f)
            or die "Failed to open $f: $!";
        my $line = <$peek>;
        $line =~ /\s-T\b/ and push @localopt, "-T";
        close $peek;

        return Test::Refute::Contract::TAP::Reader->new (
            indent => 1, exec => [ perl => @plopt => @localopt => $f ] );
    };
};

