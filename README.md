# NAME

Test::Contract - an object-oriented testing and assertion tool.

# DESCRIPTION

Test::Contract is there to add series of 
[Test::More](https://metacpan.org/pod/Test::More)-like assertions
into production code without turning the whole application
into a test script.

Also it's fairly easy to extend it with new conditions that will
play along nicely with both Test::More and Test::Contract.

# IN-APP CHECKS

Say one needs to verify that a given user input or a plug-in module
meets certain criteria:

    use strict;
    use warnings;

    use Test::Contract;

    my $c = contract {
        $_[0]->like( $user_input, qr/.../, "Format as expected" );
        $_[0]->isa_ok( $some_object, "Some::Class" );
    };

    if ($c->get_passing) {
        # so far, so good - move on!
    } else {
        croak "Contract failed: ".$c->get_tap;
    };

The `contract { CODE; }` block would produce an object containing the result of
the checks. It will also mark the contract as failed if `CODE` dies.

If more fine-grained control is needed, a `Test::Contract->new` is there
to make a fresh contract object.

Contracts can be nested just fine.

*All* of `Test::More`'s assertions have a corresponding method
in `Test::Contract`.

# EXTENDING THE ARSENAL

The most basic check in `Test::Contract` is
`$contract->refute( $what_went_unexpected, $why_we_care_about_it );`.
This may be viewed as an *inverted* `ok` or `assert`.

It is assumed that a passing check is of no interest, while a failed one
begs for details, and therefore a *false* value in the first argument
means a passing test whereas a *true* one is considered to be
also the explanation.

Think of it as an expection in a program,
or a Unix command returning 0 on success,
but *different* error codes on failure.

So all one needs to build a new assertion is to create a function
that returns false when its arguments are fine, and an explanation of failure
when they are not.

A `Test::Contract::Engine::Build` module exists to simplify the task further:

    package My::Check;
    use Exporter qw(import);

    use Test::Contract::Engine::Build;
    build_refute my_check => sub {
        my ($got, $expected) = @_;
        # ... a big and nasty check here
    }, args => 2, export => 1;

    1;

This would create an exported function called `my_check` in `My::Check`, as
well as a `my_check` method in `Test::Contract` itself. So the following code
is going to be correct:

    use Test::More tests => 1;
    use My::Check;

    my_check $foo, $bar, "foo is fine";

And this one, too:

    # inside a running application
    use Test::Contract;
    use My::Check(); # don't pollute global namespace

    my $c = Test::Contract->new;
    $c->my_check( $foo, $bar, "runtime-generated foo is fine, too" );
    if (!$c->get_passing) {
        # ouch, something went wrong with $foo and $bar
    };

It is also possible to validate the testing module itself, outputting details
on specifically the tests with unexpected results:

    use Test::Contract::Unit;
    use My::Check;

    my $c = contract {
        my_check $proper_foo, $bar;
        my_check $good_foo, $bar;
        my_check $broken_foo, $bar;
        my_check $good_foo, $wrong_bar;
    };

    is_contract $c, "1100", "my_check works as expected";
    done_testing;

`Test::Contract::Unit` may be intermixed with regular `Test::More`, as long
as it comes AFTER `Test::More`.

# A LITTLE PHYLOSOPHY

Using refutation instead of assertion is similar to the
[falsifiability](https://en.wikipedia.org/wiki/Falsifiability)
concept in modern science.

Or, quoting Leo Tolstoy,
"All happy families are alike; each unhappy family is unhappy in its own way".

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
