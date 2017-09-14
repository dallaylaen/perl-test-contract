#!/usr/bin/env perl

# An example script that verifies that a user-supplied module
# implements a predefined behaviour.
#
# Usage: <this script> <module::name>

use strict;
use warnings;
use File::Basename;
use lib dirname(__FILE__)."/../lib";

use Assert::Refute qw(contract);
use Assert::Refute::Basic;

my $module = shift;
if (!$module) {
print "Usage: $0 <module::name>
Verify that said module has a constructor and foo(), bar() accessors
";
exit 0;
};

my $c = contract {
    diag "Testing $module";
    require_ok $module;
    can_ok $module, qw(new foo bar);
    my $foo = $module->new(foo => 42, bar => 137);
    isa_ok $foo, $module;
    is $foo->foo, 42, "foo round trip";
    is $foo->bar, 137, "bar round trip";
    $foo->foo(451);
    is $foo->foo, 451, "setter round trip";
};

if ($c->get_passing) {
    print "Module $module certified as a true Foo::Bar object. Grats!\n";
    exit 0;
} else {
    print $c->get_tap;
    exit 1;
};
