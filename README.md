# NAME

Test::Refute - a unified extensible testing and assertion tool 

# DESCRIPTION

`Test::Refute` is a drop-in replacement for `Test::More`.
It has some unique features, though:

* can be used in production environment, without turning the whole application
into a test script;
* very easy to extend, and built with testability in mind;
* much faster.

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

# SYNOPSIS

`Test::Refute` may be used in place of Test::More, except for
TODO: and SKIP: blocks (yet).

    use Test::Refute;
    use_ok qw(My::Module);

    is (My::Module->answer, 42, "Life, universe, and everything");

    done_testing;

Also, `Test::Refute::Contract` may be used in production code to verify
that user input or a plugin module meet certain criteria:

    use Test::Refute::Contract;

    my $c = Test::Refute::Contract->new;
    $c->like( $user_input, qr/.../, "Format as expected" );
    $c->isa_ok( $some_object, "Some::Class" );
    if ($c->is_valid) {
         # ....
    };

Or get the best of both worlds with a declarative interface!

    use Test::Refute qw(no_init);

    my $c = contract {
        like   $user_input, qr/.../, "Format as expected";
        isa_ok $some_object, "Some::Class";
    };
    if ($c->is_valid) {
         # ....
    };

Writing your own tests is trivial. *All* you have to do is provide a subroutine
that takes arguments and returns a true scalar if something went *not as
expected*. The test is then considered failed, and the value is taken as the
reason of failure.

A Build class is then used to plant the subroutine into the Contract class
*and* make it exportable in your own class.

So this is a clumsy implementation of is()
(a real one needs to check for undefs and quoting, though).

    use Test::Refute::Build;

    build_refute my_is => sub {
        $_[0] eq $_[1] && "$_[0] != $_[1]";
    }, args => 2, export => 1;

And of course you can test it with the powerful `contract { ... }->sign(...)`
construct:

    use My::Test;
    use Test::Refute;

    my $c = contract {
        my_is( 42, 42 );
        my_is( 42, 137 );
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
