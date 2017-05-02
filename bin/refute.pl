#!/usr/bin/env perl

package Test::Contract::bin; # avoid polluting main

use strict;
use warnings;
use Carp;
use File::Find;
use Getopt::Long;
use File::Basename qw(basename dirname);

# Always use latest & greatest lib, if available
use lib dirname(__FILE__)."/../lib";
use Test::Contract::Engine::TAP;
use Test::Contract::Engine::TAP::Reader;

my $all = Test::Contract::Engine::TAP->new;

# make Getopt work with Perl-ish notation
@ARGV = map { /^(-[IMm])(.*)/ ? ($1, $2) : $_ } @ARGV;

my @inc;
my @use;
my $fake;
my @preload;
GetOptions (
    "I=s" => \@inc,
    "M=s" => sub { push @use, $_[0] =~ /=/ ? $_[0] : "$_[0]=" },
    "m=s" => \@use,
    "help" => \&usage,
    "preload=s" => \@preload,
    "faketest" => \$fake,
) or die "Bad options. See $0 --help";

sub usage {
    print <<"HELP";
$0 [options] [test_dir] ...
- A TAP-based test suite runner
Options may include:
    -I - add a library path (see perlrun)
    -M[-]Module=arg,...
    -m[-]Module - load/unload modules with/without args (see perlrun)
    --preload Module::Name,Other::Module... - experimental module caching mode
    --faketest (EXPERIMENTAL) - use Test::Contract in place of Test::More
    --help - this message
This is ALPHA software, use prove(1) when in doubt.
HELP
    exit 0;
};

my @plopt;
push @plopt, map { "-I$_" } @inc;
push @plopt, map { /=/ ? "-M$_" : "-m$_" } @use;
@preload = split /,/,join ",", @preload;

if ($fake) {
    warn "Fake Test::More in action\n";
    push @plopt,
         '-I'.dirname(__FILE__)."/../lib",
         '-MTest::Contract::Unit::Fake=more';
};

usage() unless @ARGV;

my @files;
find( sub {
    -f $_ and /\.t$/ and push @files, $File::Find::name;
}, @ARGV);

@files = sort @files;

if (@preload) {
    unshift @INC, @inc;

    if ($fake) {
        require Test::Contract::Unit::Fake;
        Test::Contract::Unit::Fake->fake_test_more;
    };

    package main;

    foreach ( @use ) {
        my ($mod, $rawarg) = split /=/, $_, 2;
        my $arg = defined $rawarg ? [split /,/, $rawarg ] : undef;
        Test::Contract::bin::load_module($mod, $arg);
    };
    foreach ( @preload ) {
        Test::Contract::bin::load_module($_);
    };
};

foreach my $f (@files) {
    my $tap = get_reader( $f );
    # TODO parallel??
    $tap->finish;
    # Sic! Here get_passing is the condition, and $tap itself is details
    $all->refute( !$tap->get_passing && $tap, $f );
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

exit !$all->get_passing;

# TODO move this into TAP::Reader after all
sub get_reader {
    my $f = shift;

    my ($in, $pid);

    if (@preload) {
        return Test::Contract::Engine::TAP::Reader->new (
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

        return Test::Contract::Engine::TAP::Reader->new (
            indent => 1, exec => [ perl => @plopt => @localopt => $f ] );
    };
};

sub load_module {
    my ($mod, $args) = @_;
    $mod =~ /^(-?)([a-z]\w+(?:::\w+)*)$/
        or croak "Bad module name: $mod";
    (my $no, $mod) = ($1, $2);
    my $file = $mod;
    $file =~ s#::#/#g;
    $file .= ".pm";
    eval { require $file; 1 } or croak $@;
    if ($no) {
        $args ||= [];
        eval { $mod->unimport(@$args); 1; }
            or croak "Failed to unload $mod: $@";
    }
    elsif ($args) {
        eval { $mod->import(@$args); 1; }
            or croak "Failed to preload $mod: $@";
    };
    warn( ($no ? "Pre":"Un")."loaded $mod from $INC{$file}\n");
};

