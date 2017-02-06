# NAME

Test::Contract - an object-oriented testing and assertion tool.

# DESCRIPTION

Test::Contract is similar to Test::More, however, it may be used in
production code without turning the whole application into a test script.

# SYNOPSIS

Say one needs to verify that user input or a plug-in module
meet certain criteria:

    use strict;
    use warnings;

    use Carp;
    use Test::Contract ();

    my $c = Test::Contract->new;
    $c->like( $user_input, qr/.../, "Format as expected" );
    $c->isa_ok( $some_object, "Some::Class" );
    if ($c->get_passing) {
        # so far, so good ....
    } else {
        carp "Contract failed: ".$c->get_tap;
    };

Or if a check is complex and cannot be broken down into Test::More-like
primitives:

    $c->refute( my_check( @args ), "Message" );

Here `my_check` MUST return the reasons why `@args` do *not* pass the test,
or return nothing.
See also `Test::Contract::Build` module for extening available checks.

# PHYLOSOPHY

A `refute( $condition, $message )` is a function that merely reports success
if `$condition` is false, but complains loudly when it's true.
This is the *inverse* of an assert.
This is similar to Unix commands who succeed silently and fail loudly.

This is also similar to the
[falsifiability](https://en.wikipedia.org/wiki/Falsifiability)
concept in modern science.

Or quoting Leo Tolstoy,
"All happy families are alike; each unhappy family is unhappy in its own way".

These *refute*s may be then applied as either assertions, or (unit) test
building blocks.

# EXTENDING THE CHECKS

Writing your own tests is trivial. *All* you have to do is provide a subroutine
that takes arguments and returns a true scalar if something went *not as
expected*. The test is then considered failed, and the value is taken as the
reason of failure.

A Build class is then used to plant the subroutine into the Contract class
*and* make it exportable in your own class.

So this is a clumsy implementation of is()
(a real one needs to check for undefs and quoting, though).

    use Test::Contract::Build;

    build_refute my_is => sub {
        $_[0] eq $_[1] && "$_[0] != $_[1]";
    }, args => 2, export => 1;

And of course you can test it with the powerful `contract { ... }->sign(...)`
construct:

    # This can be intermixed with Test::More/Test::Builder, provided
    # Test::Contract is loaded *after* them.

    use strict;
    use warnings;
    use My::Test;
    use Test::Contract;

    my $c = contract {
        my_is( 42, 42, "Life is life" );
        my_is( 42, 137, "Life is fine (1/137 =~ fine structure constant)" );
    };
    $c->sign ( "10" ); # 2 tests, 1 pass, 1 fail
    note $c->get_tap;  # JFYI

    done_testing;

# INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

# BUGS

Lots of them. This software is still in alpha stage.

Please report bugs to https://github.com/dallaylaen/perl-test-refute/issues

# COPYRIGHT AND LICENSE

This program is free software and can be (re)distributed on the same terms
as Perl itself.

Copyright (c) 2017 Konstantin S. Uvarin
