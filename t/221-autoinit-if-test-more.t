#!/usr/bin/env perl

use strict;
use warnings;

{
    package My::Test;
    use Exporter qw(import);
    use Test::Contract::Engine::Build;
    build_refute my_ok => sub { !shift }, export => 1;
};

use Test::More;
My::Test->import("my_ok");

ok eval {
    my_ok(1, "Works as expected");
}, "Test lives";

done_testing;
