#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute::Engine::TAP;

sub fork_is (&@); ## no critic

my $tap = Assert::Refute::Engine::TAP->new;

fork_is {
    # Need to die on redefines. No, just fatal warns won't cut it.
    local $SIG{__WARN__} = \&Carp::confess;

    # Use by hand
    require Test::More;
    Test::More->import();
    require Assert::Refute::Unit;
    Assert::Refute::Unit->import();

    ok (1, "All good so far" );
    my $c = contract( sub {
        my $x = shift;
        $x->is (1, 0);
        $x->like ("foo", "f.*");
    } );

    contract_is( $c, "01", "T::C specific" );
    my $main = Assert::Refute::Unit->engine;
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
# at FILE line NNN
1..3
# Looks like you failed 1 test of 3
EOF

fork_is {
    # Need to die on redefines. No, just fatal warns won't cut it.
    local $SIG{__WARN__} = \&Carp::confess;

    # Use by hand
    require Test::More;
    Test::More->import();
    require Assert::Refute::Unit;
    Assert::Refute::Unit->import();

    ok (1, "pass" );
    my $c = Assert::Refute::Unit->engine;

    note( "count=", $c->get_count );
    note( "error=", $c->get_error_count );
    note( "passing=", $c->get_passing ? 1 : 0 );

    ok (0, "fail");
    note( "count=", $c->get_count );
    note( "error=", $c->get_error_count );
    note( "passing=", $c->get_passing ? 1 : 0 );

    done_testing();
} <<"EOF";
ok 1 - pass
# count=1
# error=0
# passing=1
not ok 2 - fail
# Failed test 'fail'
# at FILE line NNN
# count=2
# error=1
# passing=0
1..2
# Looks like you failed 1 test of 2
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
    $data =~ s/\.$//gm;
    $tap->is ($data, $exp, "fork_is");
};
