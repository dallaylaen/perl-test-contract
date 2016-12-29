package Test::Refute::Basic;

use strict;
use warnings;
our $VERSION = 0.0108;

=head1 NAME

Test::Refute::Basic - a set of most common tests for Test::Refute suite

=head1 DESCRIPTION

This module contains most common test conditions similar to those in
L<Test::More>, like C<is $got, $expected;> or C<like $got, qr/.../>.
It is automatically loaded by both L<Test::Refute>
and L<Test::Refute::Contract>, so you probably needn't to load it directly.

=head1 FUNCTIONS

All functions are prototyped to be used without parentheses and
exported by default.
In addition, a C<Test::Refute::Contract-E<gt>function_name> method with
the same signature is generated for each of them (see L<Test::Refute::Build>).

=cut

use Carp;
use parent qw(Exporter);
use Test::Refute::Build qw(build_refute refute_engine);

=head2 is $got, $expected, "explanation"

Doesn't handle undef values yet, will be fixed soon.

=cut

build_refute is => sub {
    my ($got, $exp) = @_;

    if (defined $got xor defined $exp) {
        return "unexpected ". ((defined $got) ? "'$got'" : "undef value");
    };

    return '' if !defined $got or $got eq $exp;
    return "Got:      $got\nExpected: $exp";
}, args => 2, export => 1;

=head2 ok $condition, "explanation"

=cut

build_refute ok => sub {
    my $got = shift;

    return !$got;
}, args => 1, export => 1;

=head2 use_ok

Not really tested well.

=cut

build_refute use_ok => sub {
    my $mod = shift;
    my $file = $mod;
    $file =~ s#::#/#g;
    $file .= ".pm";
    eval { require $file; $mod->import; 1 } and return '';
    return "Failed to load $mod: ".($@ || "(unknown error)");
}, args => 1, export => 1;

=head2 cpm_ok $arg, 'operation', $arg2, "explanation"

Currently supported: C<E<lt> E<lt>= == != E<gt>= E<gt>>
C<lt le eq ne ge gt>

Fails if any argument is undefined.

=cut

my %compare;
$compare{$_} = eval "sub { return \$_[0] $_ \$_[1]; }" ## no critic
    for qw( < <= == != >= > lt le eq ne ge gt );

build_refute cmp_ok => sub {
    my ($x, $op, $y) = @_;

    my @missing;
    push @missing, 1 unless defined $x;
    push @missing, 2 unless defined $y;
    return "Argument(@missing) undefined"
        if @missing;

    my $fun = $compare{$op};
    croak "Comparison '$op' not implemented"
        unless $fun;

    return '' if $fun->($x, $y);
    return "$x\nis not '$op'\n$y";
}, args => 3, export => 1;

=head2 like $got, qr/.../, "explanation"

=head2 like $got, "regexp", "explanation"

B<UNLIKE> L<Test::More>, accepts string argument just fine.

If argument is plain scalar, it is anchored to match the WHOLE string,
so that "foobar" does NOT match "ob", but DOES match ".*ob.*".

=cut

build_refute like => sub {
    my ($str, $reg) = @_;

    $reg = qr#^(?:$reg)$# unless ref $reg eq 'Regexp';
        # retain compatibility with Test::More
    return '' if $str =~ $reg;
    return "$str\ndoesn't match\n$reg";
}, args => 2, export => 1;

1;
