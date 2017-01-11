package Test::Simple;

use strict;
use warnings;
our $VERSION = 0.04;

=head1 STOP!

This is a fake Test::More.
It is only here to test how Test::Contract behaves in place of Test::More
without rewriting a lot of test scripts.

=cut

use Carp;
use Test::Contract qw(no_init);

# Just re-export everything
our @ISA = qw(Test::Contract Exporter);
our @EXPORT = @Test::Contract::EXPORT;

END {
    if (Test::Builder->can("import")) {
        carp "Real Test::More loaded, the script may misbehave";
    };
};

1;

