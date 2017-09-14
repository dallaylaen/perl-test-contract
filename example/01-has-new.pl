#!/usr/bin/env perl

# A brief example showing Assert::Refute usage.
# An unforeknown module is being tested for having a new() method
# returning an instance of itself.

use strict;
use warnings;
use File::Basename;

# Always latest and greatest libs
use lib dirname(__FILE__)."/../lib";
use Assert::Refute;

my $mod = shift;
if (!$mod) {
    print "Usage: $0 <module_name>\n";
    print "Test that a module has constructor returning itself";
    exit 0;
};
if ($mod !~ /^[a-z]\w*(?:::\w+)*$/i) {
    die "Module name must be like Some::Thing";
};

# Start a contract
my $c = Assert::Refute->new;

# Check conditions
$c->require_ok($mod)
    and $c->can_ok($mod, 'new')
    and $c->isa_ok($mod->new, $mod);

# Output conclusion
print $c->get_tap;
print "$mod ". ($c->get_passing ? "has": "doesn't have")." proper new()\n";

# return status
exit $c->get_error_count;


