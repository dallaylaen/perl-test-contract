#!/usr/bin/env perl

use strict;
use warnings;

require Carp;
require Exporter;
require parent;
require Scalar::Util;

$| = 1;
# don't use Test::More or Test::Refute

sub fork_is (&$$);

fork_is {
    require Test::Refute;
    Test::Refute->import;
    is (42, 42, "pass");
    is (42, 43, "fail");
    done_testing ();
} 1, <<IS;
ok 1 - pass
not ok 2 - fail
1..2
IS



my $n_test;
my $n_fail;
my $child;

END {
    if (!$child) {
        if ($n_fail) {
            print "Bail out! Bootstrapping Test::Refute failed\n";
            exit $n_fail;
        } else {
            print "1..".($n_test || 0);
            exit 0;
        };
    };
};

sub fork_is (&$$) {
    my ($code, $return, $exp) = @_;

    my $no_exception = "\n~~~ No exception\n";
    $exp = "~~~ $return\n$exp$no_exception";

    $n_fail++;
    pipe( my $read, my $write ) or die "Failed to pipe: $!";
    my $pid = fork;
    defined $pid or die "Fork failed: $!";

    if (!$pid) {
        # CHILD SECTION
        $child++;
        open STDOUT, ">&", $write or die "dup2 failed (child): $!";
        close $read;
        $code->();
        print $no_exception;
        exit;
        # END CHILD SECTION
    };

    close $write;
    local $/;
    my $got = <$read>;
    wait;
    my $value = $? >> 8;

    print "# RAW $_\n" for split "\n", $got;
    $got =~ s/#.*?\n//sg;
    $got = join "\n", "~~~ $value", $got;
    print "# GOT $_\n" for split "\n", $got;

    $n_test++;
    if ($got eq $exp) {
        $n_fail--;
        print "ok $n_test\n";
    } else {
        print "not ok $n_test\n";
        print "# EXP $_\n" for split /\n/, $exp;
    };
};
