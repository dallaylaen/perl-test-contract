#!/usr/bin/env perl

use strict;
use warnings FATAL => qw(all);

# This is a Test::Contract bootstrap script.
# We don't have Test::Contract yet to prove that Test::Contract works.
# So we bootstrap it in several stages.
# First, we postulate a naive my_is( $got, $expected, $comment ) function
#     that just works due to its simplicity.
# Also we add a strip() function that is basically a regexp
#     filtering out comments.
# Then, we use these (and Perl's IO redirection) to prove that
#     Test::Contract::Engine::TAP works as expected, ESPECIALLY when
#     something is wrong (fail tests, bail out etc).
# Then, we use my_is() to prove that contract { ... } really does what it's
#     supposed to do. At least that it can output a failing contract.
# Then, we use my_is() to prove that Contract->sign works. Contract->sign is
#     enough to show that certain test function works (and fails) as expected.

# defined at EOF
sub my_is ($$$); ## no critic
sub strip;

# my_is(42, 42, "is works");
# my_is(42, 43, "is fails");

require Test::Contract::Engine::TAP;
my_is !!Test::Contract::Engine->can("new"), 1, "Test::Contract::Engine present";

# Abbreviate capture
sub capture {
    my $to = shift;
    open (my $fd, ">", $to)
        or die "Redirect failed: $!";
    return Test::Contract::Engine::TAP->new( out => $fd );
};

my $c;
my $output;
print "# Testing TAP backend\n";

$c = capture( \$output );
$c->done_testing;
my_is ($output, "1..0\n", "empty plan");
my_is (!!$c->get_passed, 1, "contract valid");
my_is ($c->get_count, 0, "no tests run");

$c = capture( \$output );
$c->ok( 1, "Pass" );
$c->done_testing;
my_is ($output, "ok 1 - Pass\n1..1\n", "happy path");
my_is (!!$c->get_passed, 1, "contract valid");
my_is ($c->get_count, 1, "1 test run");

$c = capture( \$output );
$c->ok( 1, "Pass" );
$c->ok( 0, "Fail" );
$c->done_testing;
my_is strip($output), "ok 1 - Pass\nnot ok 2 - Fail\n1..2\n", "Failed ok()";
my_is (!$c->get_passed, 1, "contract NOT valid");
my_is ($c->get_count, 2, "1 test run");

# OK, this is a fragile hack. We know that TAP driver doesn't save passed tests
# names, so rid of them. Sorry for this mess. Maybe just comment it out
# if format changes...
my $output_no_ok = strip($output);
$output_no_ok =~ s/^(ok \d+).*/$1/mg;
my_is $c->get_tap(0), $output_no_ok , "get_tap works, too";

$c = capture( \$output );
$c->ok( 1, "Pass" );
$c->bail_out( "Reason" );
my_is strip($output), "ok 1 - Pass\nBail out! Reason\n", "Bail out";
my_is (!$c->get_passed, 1, "contract NOT valid");
my_is ($c->get_count, 1, "1 test run");

$c = capture( \$output );
$c->note( "note", {} );
$c->diag( "diag", [] );
my_is( $output, "## note{}\n# diag[]\n", "note/diag work");


print "# Testing contract...\n";

Test::Contract::Engine->import("contract");
sub contract (&;$); ## no critic # this dies if we change proto

$c = contract {
};
my_is ref $c, "Test::Contract::Engine", "contract yields T::R::Contract";
my_is $c->get_count, 0, "Nothing done";
my_is $c->get_error_count, 0, "No errors";
my_is !$c->get_passed, "", "valid = true";
my_is $c->get_tap(0), "1..0\n", "plan 1..0";

$c = contract {
    $_[0]->refute(0, "pass");
    $_[0]->refute(1, "fail");
};
my_is ref $c, "Test::Contract::Engine", "(2) contract yields T::R::Contract";
my_is $c->get_count, 2, "count = 2";
my_is $c->get_error_count, 1, "error = 1";
my_is !$c->get_passed, 1, "valid = false";
my_is $c->get_tap(0), "ok 1 - pass\nnot ok 2 - fail\n1..2\n"
    , "output as expected in get_tap";

$c = contract {
    contract {
        $_[0]->ok(1, "pass");
        $_[0]->ok(0, "fail");
    }->sign(1)->sign(10)->sign("01")->sign(101);
};
my $fail = $c->get_failed;
my_is (!!$fail->{1}, 1, "nested fail 1");
my_is (!!$fail->{2}, "", "nested pass 2");
my_is (!!$fail->{3}, 1, "nested fail 3");
my_is (!!$fail->{4}, 1, "nested fail 4");

print "# Now some fork to check the whole Test::Contract magic is there\n";

my ($pipe_r, $pipe_w);
pipe ($pipe_r, $pipe_w)
    or die "Pipe failed: $!";
my $pid = fork;
defined $pid
    or die "Failed to fork: $!";

if (!$pid) {
    # CHILD
    open STDOUT, ">&", $pipe_w;
    close $pipe_r;
    require Test::Contract;
    Test::Contract->import;
    is (42, 43, "fail");
    like (42, qr/\d+/, "pass");
    new_ok( "Test::Contract::Engine" ); # ok, too
    done_testing();
    exit;
    # END CHILD
};

close $pipe_w;
$output = do {
    local $/;
    <$pipe_r>
};

my_is strip( $output ), <<OUT, "Fork as expected";
not ok 1 - fail
ok 2 - pass
ok 3
1..3
OUT

waitpid( -1, 0 );
my_is $?>>8, 1, "returned 1 for 1 failed test";

print "# Done testing...\n";
print "# If passed, at least Test::Contract, contract{}, and \$contract->sign\n";
print "#     can be used without much risk\n";

sub strip {
    my $x = shift || '';
    $x =~ s/(\s*#[^\n]*\n)+/\n/gs;
    return $x;
};

my $fails;
my $ntest;

sub my_is ($$$) { ## no critic
    my ($x, $y, $comment) = @_;

    no warnings 'uninitialized'; ## no critic
    $ntest++;
    if ($x eq $y) {
        print "ok $ntest - $comment\n";
    } else {
        $fails++;
        print "not ok $ntest - $comment\n";
        print "# Got: '$x'\n";
        print "# Exp: '$y'\n";
    };
};

my $done = !$fails;

END {
    if ($pid || !defined $pid) {
        if (!$done) {
            print "Bail out! my_ok bootstrap failed $fails/$ntest tests". "\n";
            exit 1;
        } else {
            print "1..$ntest\n";
            exit 0;
        };
    };
};
