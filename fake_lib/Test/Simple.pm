package Test::Simple;

use strict;
use warnings;
our $VERSION = 0.0210;

=head1 STOP!

This is a fake Test::More.
It is only here to test how Test::Contract::Unit behaves in place of Test::More
without rewriting a lot of test scripts.

=cut

use Carp;
use Test::More;

# Just re-export everything
our @ISA = qw(Test::More);
our @EXPORT = @Test::More::EXPORT;

END {
    if (Test::Builder->can("import")) {
        carp "Real Test::More loaded, the script may misbehave";
    };
};

1;

