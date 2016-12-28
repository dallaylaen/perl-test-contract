#!/usr/bin/env perl

use strict;
use warnings;

# We must load Basic.pm first, before all else
# so that cover -t doesn't lie about coverage

eval {
    require Test::Refute::Engine;
    print "ok 1 - require basic checks\n1..1\n";
} or do {
    print "Bail out! Loading basic checks failed: $@\n";
    exit 1;
};
