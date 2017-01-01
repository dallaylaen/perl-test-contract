package Test::Refute::Basic;

use strict;
use warnings;
our $VERSION = 0.0111;

=head1 NAME

Test::Refute::Basic - a set of most common tests for Test::Refute suite

=head1 DESCRIPTION

B<DO NOT USE THIS MODULE DIRECTLY>.
Instead, load L<Test::Refute> for functional interface,
or L<Test::Refute::Contract> for object-oriented one.
Both would preload this module.

This module contains most common test conditions similar to those in
L<Test::More>, like C<is $got, $expected;> or C<like $got, qr/.../>.
Please refer here for an up-to-date reference.

=head1 FUNCTIONS

All functions are prototyped to be used without parentheses and
exported by default.
In addition, a C<Test::Refute::Contract-E<gt>function_name> method with
the same signature is generated for each of them (see L<Test::Refute::Build>).

=cut

use Carp;
use parent qw(Exporter);
use Test::Refute::Build;
use Test::Refute::Basic::Is;
our @EXPORT = @Test::Refute::Basic::Is::EXPORT;

=head2 is $got, $expected, "explanation"

Check for equality, undef equals undef and nothing else.

=cut

# See Test::Refute::Basic::Is for implementation

=head2 is $got, $expected, "explanation"

The reverse of is().

=cut

build_refute isnt => sub {
    my ($got, $exp) = @_;
    return if defined $got xor defined $exp;
    return "Unexpected: ".to_scalar($got)
        if !defined $got or $got eq $exp;
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

=head2 unlike $got, "regexp", "explanation"

The exact reverse of the above.

B<UNLIKE> L<Test::More>, accepts string argument just fine.

If argument is plain scalar, it is anchored to match the WHOLE string,
so that "foobar" does NOT match "ob", but DOES match ".*ob.*".

=cut

build_refute like => sub {
    _like_unlike( $_[0], $_[1], 0 );
}, args => 2, export => 1;

build_refute unlike => sub {
    _like_unlike( $_[0], $_[1], 1 );
}, args => 2, export => 1;

sub _like_unlike {
    my ($str, $reg, $reverse) = @_;

    $reg = qr#^(?:$reg)$# unless ref $reg eq 'Regexp';
        # retain compatibility with Test::More
    return '' if $str =~ $reg xor $reverse;
    return "$str\n".($reverse ? "unexpectedly matches" : "doesn't match")."\n$reg";
};

=head2 can_ok

=cut

build_refute can_ok => sub {
    my $class = shift;

    my @missing = grep { !$class->can($_) } @_;
    return @missing && to_scalar($class, 0)." has no methods ".join ", ", @missing;
}, no_pop => 1, export =>1;

=head2 contract_is Test::Refute::Contract, "11000101", "explanation"

Check that tests denoted by 1 pass, and those denoted by 0 fail.
An verbose summary is diag'ed in case of failure.

=cut

# See Test::Refute::Basic::Is for implementation

1;
