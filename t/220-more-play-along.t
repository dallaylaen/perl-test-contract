#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract::Engine::TAP;

sub fork_is (&@); ## no critic

my $tap = Test::Contract::Engine::TAP->new;

fork_is {
    # Need to die on redefines. No, just fatal warns won't cut it.
    local $SIG{__WARN__} = \&Carp::confess;

    # Use by hand
    require Test::More;
    Test::More->import();
    require Test::Contract;
    Test::Contract->import();

    ok (1, "All good so far" );
    my $c = contract( sub {
        my $x = shift;
        $x->is (1, 0);
        $x->like ("foo", "f.*");
    } );

    contract_is( $c, "01", "T::C specific" );
    my $main = Test::Contract->get_engine;
    $main->diag("diag something");
    $main->note("note something");

    ok (0, "Add some failing test" );

    done_testing();
} <<"EOF";
ok 1 - All good so far
ok 2 - T::C specific
# diag something
# note something
not ok 3 - Add some failing test
# Failed test 'Add some failing test'
# at FILE line NNN.
1..3
# Looks like you failed 1 test of 3.
EOF



$tap->done_testing;
exit !$tap->get_passing;

sub fork_is (&@){ ## no critic
    my ($code, $exp) = @_;

    pipe (my $read, my $write)
        or die "Failde to pipe: $!";
    defined( my $pid = fork )
        or die "Failed to fork: $!";

    if (!$pid) {
        # CHILD
        close $read;
        open (STDOUT, ">&", $write)
            or die "Redirect failed: $!";
        open (STDERR, ">&", $write)
            or die "Redirect failed: $!";
        $code->();
        exit 0;
        # CHILD END
    };

    close $write;
    local $/;

    my $data = <$read>;

    $data =~ s/(at.*?line)\s+\d+/at FILE line NNN/g;
    $data =~ s/  +/ /g;
    $data =~ s/\n\n+/\n/gs;
    $tap->is ($data, $exp, "fork_is");
};
