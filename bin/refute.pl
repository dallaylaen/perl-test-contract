#!/usr/bin/env perl

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

my @inc;
my @preload;
GetOptions (
    "I=s" => \@inc,
    "help" => \&usage,
    "preload=s" => \@preload,
) or die "Bad options. See $0 --help";

my @plopt;
push @plopt, map { "-I$_" } @inc;
@preload = split /,/,join ",", @preload;

my @files;
find( sub {
    -f $_ and /\.t$/ and push @files, $File::Find::name;
}, @ARGV);

@files = sort @files;

if (@preload) {
    unshift @INC, @inc;

    package isolated;
    foreach my $mod( @preload ) {
        my $fname = $mod;
        $fname =~ s#::#/#g;
        $fname .= ".pm";
        require $fname;
        warn "Preloaded $mod from $INC{$fname}\n";
    };
};

foreach my $f (@files) {
    my $tap = get_reader( $f );
#    warn "[$$] testing $f\n";
    # TODO parallel??
    $tap->finish;
    not_ok $tap->get_failed && $tap, $f;
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

exit !$all->is_valid;

sub get_reader {
    my $f = shift;

    my ($in, $pid);

    if (@preload) {
        pipe ($in, my $out)
            or die "Aborting tests: pipe failed: $!";
        defined ($pid = fork)
            or die "Aborting tests: fork failed: $!";

        if (!$pid) {
            # CHILD
            close $in;
            open STDOUT, ">&", $out
                or die "dup2 failed: $!";

            @ARGV = ();
            Test::Refute->reset;
            $FindBin::Bin = $FindBin::Bin = dirname($f);

            eval { package isolated; do $f; 1 }
                or do {
                    not_ok $! || 1, "died";
                    exit 1;
                };
            exit 0;
            # CHILD END
        };

        # PARENT
        close $out;
    } else {
        my @localopt;
        open (my $peek, "<", $f)
            or die "Failed to open $f: $!";
        my $line = <$peek>;
        $line =~ /\s-T\b/ and push @localopt, "-T";
        close $peek;

        $pid = open ($in, "-|", perl => @plopt => @localopt => $f)
            or do {
                ok 0, $f;
                diag $!;
                next;
            };
    };

    my $tap = Test::Refute::Contract::TAP::Reader->new (
        in => $in, pid => $pid, indent => 1 );
};

