# NAME

Test::Refute - a lightweight asserting system and test suite

# DESCRIPTION

A `refute( $condition, $message )` is a function that merely reports success
if `$condition` is false, but complains loudly when it's true.
This is the *inverse* of an assert.
This is similar to Unix commands that complete silently and fail loudly.

Or as Leo Tolstoy said,
"All happy families are alike; each unhappy family is unhappy in its own way".

These *refute*s may be then applied as either assertions, or (unit) test
building blocks.

# SYNOPSIS

`Test::Refute` may be used in place of Test::More.
However, `done_testing` is *required*, and plan not implemented yet.

    use Test::Refute;
    use_ok qw(My::Module);

    is ($answer, 42, "Life, universe, and everything");

    done_testing;


