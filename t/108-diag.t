#!/usr/bin/env perl

use strict;
use warnings;
use Test::Contract;

my $c = contract {
    diag "Foo";
    diag "Foo again", [1..5];
    note "Bar";
    note "Baz ", explain { foo => 42 };
};

my @lines = grep { /^#/ } split /\n/, $c->get_tap(2);

is scalar @lines, 4;
is $lines[0], '# Foo', 'single diag';
is $lines[1], '# Foo again[1, 2, 3, 4, 5]', 'diag + auto-explain';
is $lines[2], '## Bar', 'single note';
is $lines[3], '## Baz {"foo":42}', 'note + explain';

done_testing;
