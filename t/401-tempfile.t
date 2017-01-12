#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract;
use Test::Contract::Tempfile qw(mktemp);

my $where = $ENV{TEMP} || $ENV{TMP} || '/tmp';
my $tpl = "$where/test-contract-XXXXXXXXX";
my @files;
END { unlink $_ or $!{ENOENT} or warn "Failed unlink $_: $!" for @files };
my @warn;
local $SIG{__WARN__} = sub { push @warn, $_[0] };

contract {
    my ($fh, $name) = mktemp($tpl);

    push @files, $name;
    print $fh "test pass";
    close $fh;

    ok(1, "pass");
};

is @warn, 0, "no warnings issued";
diag "WARN: ", $_ for @warn;
@warn = ();

contract {
    my ($fh, $name) = mktemp($tpl);

    push @files, $name;
    print $fh "test fail";
    close $fh;

    ok(0, "fail");
};

ok( !-f $files[0], "First file deleted" );
ok(  -f $files[1], "Second file exists" );



done_testing;
