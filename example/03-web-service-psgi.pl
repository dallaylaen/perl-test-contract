#!/usr/bin/env perl

# Example showing a web-service.
# It checks that an integer 'value' is between 'min' and 'max', also integer
# However, if the inputs are not as expected, a 422 error message
#     with contract execution log is shown instead.
# Usage: $ plackup <this_file> [--listen :<port>]
# This will run a web-server and let you check the inputs as:
#     http://localhost:5000/?min=1&max=9&value=5  #ok
#     http://localhost:5000/?min=1&max=9&value=-1 #ok
#     http://localhost:5000/?min=9&max=1&value=5  #not ok
#     http://localhost:5000/?min=1&max=9          #not ok

use strict;
use warnings;
use Plack::Request;
use File::Basename;

use lib dirname(__FILE__)."/../lib";
use Assert::Refute qw(contract);
use Assert::Refute::Basic;

# This is just the PSGI spec
my $app = sub {
    my $req = Plack::Request->new(shift);
    my ($min, $max, $value) = map { $req->param($_) } qw(min max value);

    # Validate inputs
    my $c = contract {
        like $min, '-?\d+', "min is numeric";
        like $max, '-?\d+', "max is numeric";
        like $value, '-?\d+', "value is numeric";
        cmp_ok $min, '<', $max, "min < max";
    };

    # Output error
    if (!$c->get_passing) {
        return [422, [ 'Content-Type' => 'text/plain' ], [$c->get_tap]];
    };

    # Request is fine - process it
    my $where = ($min <= $value && $value <= $max) ? "within" : "outside";
    return [200, [ 'Content-Type' => 'text/plain' ]
        , [ "$value is $where the [$min, $max] interval"]];
};

