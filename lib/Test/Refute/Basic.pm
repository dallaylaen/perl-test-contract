package Test::Refute::Basic;

use strict;
use warnings;
our $VERSION = 0.0104;

use parent qw(Exporter);
use Test::Refute::Build qw(build_refute refute_engine);

build_refute is => sub {
    my ($got, $exp) = @_;

    return '' if $got eq $exp;
    return "Got:      $got\nExpected: $exp";
}, args => 2, export => 1;

build_refute ok => sub {
    my $got = shift;

    return !$got;
}, args => 1, export => 1;

build_refute use_ok => sub {
    my $mod = shift;
    my $file = $mod;
    $file =~ s#::#/#g;
    $file .= ".pm";
    eval { require $file; $mod->import; 1 } and return '';
    return $@ || "Failed to load $mod";
}, args => 1, export => 1;

my %compare;
$compare{$_} = eval "sub { return \$_[0] $_ \$_[1]; }"
    for qw( < <= == != >= > lt le eq ne ge gt );

build_refute cmp_ok => sub {
    my ($x, $op, $y) = @_;

    return '' if $compare{$op}->($x, $y);
    return "$x\nis not '$op'\n$y";
}, args => 3, export => 1;

build_refute like => sub {
    my ($str, $reg) = @_;

    $reg = qr#^(?:$reg)$#;
    return '' if $str =~ $reg;
    return "$str\ndoesn't match\n$reg";
}, args => 2, export => 1;

build_refute ilike => sub {
    my ($str, $reg) = @_;

    $reg = qr#^(?:$reg)$#i;
    return '' if $str =~ $reg;
    return "$str\ndoesn't match\n$reg";
}, args => 2, export => 1;

1;
