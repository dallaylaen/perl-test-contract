#!/usr/bin/env perl

package Assert::Refute::bin; # avoid polluting main

use strict;
use warnings;
use Carp;
use File::Find;
use Getopt::Long;
use File::Basename qw(basename dirname);

# Always use latest & greatest lib, if available
use lib dirname(__FILE__)."/../lib";
use Assert::Refute::Engine::TAP;
use Assert::Refute::Engine::TAP::Reader;

my $all = Assert::Refute::Engine::TAP->new;

# make Getopt work with Perl-ish notation
@ARGV = map { /^(-[IMm])(.*)/ ? ($1, $2) : $_ } @ARGV;

my @inc;
my @use;
my $fake;
my @preload;
Getopt::Long::Configure("no_ignore_case");
GetOptions (
    "I=s" => \@inc,
    "M=s" => sub { push @use, "-M$_[1]" },
    "m=s" => sub { push @use, "-m$_[1]" },
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
    --faketest (EXPERIMENTAL) - use Assert::Refute in place of Test::More
    --help - this message
This is ALPHA software, use prove(1) when in doubt.
HELP
    exit 0;
};

my @plopt;
push @plopt, map { "-I$_" } @inc;
push @plopt, @use;
@preload = split /,/,join ",", @preload;

if ($fake) {
    warn "Fake Test::More in action\n";
    push @plopt,
         '-I'.dirname(__FILE__)."/../lib",
         '-MAssert::Refute::Unit::Fake=more';
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
        require Assert::Refute::Unit::Fake;
        Assert::Refute::Unit::Fake->fake_test_more;
    };

    foreach my $mod( @preload ) {
        load_module("-m$mod");
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
        return Assert::Refute::Engine::TAP::Reader->new (
            indent => 1, replace_stdout => 1, eval => sub {
                $0 = $f;
                @ARGV = ();

                foreach my $mod ( @use ) {
                    load_module($mod);
                };

                eval {
                    package main;
                    do $f;
                    die $@ if $@;
                    1;
                } or do {
                    print "not ok 1 - died: $@\n1..1\n";
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

        return Assert::Refute::Engine::TAP::Reader->new (
            indent => 1, exec => [ perl => @plopt => @localopt => $f ] );
    };
};

sub load_module {
    my $spec = shift;
    $spec =~ /^(-[Mm])(-?)([A-Za-z]\w+(?:::\w+)*)(?:=(.*))?$/
        or croak "Bad module spec: $spec";
    my ($import, $no, $mod, $rawarg) = ($1, $2, $3, $4);
    $import = ($import eq "-M"); # to bool

    croak "Impossible module spec: $spec"
        if !$import and ($no or defined $rawarg);

    warn "Loading $spec as '$import', '$no', '$mod', '".($rawarg||'')."'";

    my $args = defined $rawarg ? [split /,/, $rawarg] : [];

    my $file = $mod;
    $file =~ s#::#/#g;
    $file .= ".pm";
    eval { package main; require $file; 1 }
        or croak "Failed to preload $mod: $@";
    if ($no) {
        eval { package main; $mod->unimport(@$args); 1; }
            or croak "Failed to unload $mod: $@";
    }
    elsif ($import) {
        eval { package main; $mod->import(@$args); 1; }
            or croak "Failed to preload $mod: $@";
    };
    warn( ($no ? "Un":"Pre")."loaded $mod from $INC{$file}\n");
};

