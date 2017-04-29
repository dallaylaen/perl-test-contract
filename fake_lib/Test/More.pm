package Test::More;

use strict;
use warnings;
our $VERSION = 0.0210;

=head1 STOP!

This is a fake Test::More.
It is only here to test how Test::Contract::Unit behaves in place of Test::More
without rewriting a lot of test scripts.

=cut

use Carp;
use Test::Contract::Unit;

# Just re-export everything
our @ISA = qw(Test::Contract::Unit);
our @EXPORT = @Test::Contract::Unit::EXPORT;

sub import {
    my $class = shift;
    unshift @_, "no_plan"
        unless( $_[0] and ($_[0] eq 'plan' or $_[0] eq 'no_plan') );
    unshift @_, $class;
    goto \&Test::Contract::Unit::import; ## no critic
};

END {
    if (Test::Builder->can("import")) {
        carp "Real Test::More loaded, the script may misbehave";
    };
};

1;
