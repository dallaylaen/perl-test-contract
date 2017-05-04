package Test::Contract::Basic;

use strict;
use warnings;
our $VERSION = 0.0303;

=head1 NAME

Test::Contract::Basic - a set of most common tests for Test::Contract suite

=head1 DESCRIPTION

This module contains most common test conditions similar to those in
L<Test::More>, like C<is $got, $expected;> or C<like $got, qr/.../;>.

Using L<Test::Contract::Unit> would imply being inside a unit test script,
whereas this module would just export some testing functions.

=head1 FUNCTIONS

All functions below are prototyped to be used without parentheses and
exported by default. Scalar context is imposed onto arguments, so

    is @foo, @bar;

would actually compare arrays by length.

If a C<contract { ... }> is in action, the results of each assertion
will be recorded there. See L<Test::Contract> for more.
If L<Test::Contract::Unit>/L<Test::More> is in action,
a unit testing script is assumed.
If neither is true, an exception is thrown.

In addition, a C<Test::Contract-E<gt>function_name> method with
the same signature is generated for each of them
(see L<Test::Contract::Engine::Build>).

=cut

use Carp;
use parent qw(Exporter);
use Test::Contract::Engine::Build;
our @EXPORT;

=head2 is $got, $expected, "explanation"

Check for equality, undef equals undef and nothing else.

=cut

build_refute is => sub {
    my ($got, $exp) = @_;

    if (defined $got xor defined $exp) {
        return "unexpected ". to_scalar($got, 0);
    };

    return '' if !defined $got or $got eq $exp;
    return sprintf "Got:      %s\nExpected: %s"
        , to_scalar($got, 0), to_scalar($exp, 0);
}, args => 2, export => 1;

=head2 isnt $got, $expected, "explanation"

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

# TODO write it better
build_refute use_ok => sub {
    my ($mod, @arg) = @_;
    my $caller = caller(1);
    eval "package $caller; use $mod \@arg; 1" and return ''; ## no critic
    return "Failed to use $mod: ".($@ || "(unknown error)");
}, list => 1, export => 1;

build_refute require_ok => sub {
    my ($mod, @arg) = @_;
    my $caller = caller(1);
    eval "package $caller; require $mod; 1" and return ''; ## no critic
    return "Failed to require $mod: ".($@ || "(unknown error)");
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
    croak "cmp_ok(): Comparison '$op' not implemented"
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
    return 'unexpected undef' if !defined $str;
    return '' if $str =~ $reg xor $reverse;
    return "$str\n".($reverse ? "unexpectedly matches" : "doesn't match")."\n$reg";
};

=head2 can_ok

=cut

build_refute can_ok => sub {
    my $class = shift;

    croak ("can_ok(): no methods to check!")
        unless @_;

    return 'undefined' unless defined $class;
    return 'Not an object: '.to_scalar($class)
        unless UNIVERSAL::can( $class, "can" );

    my @missing = grep { !$class->can($_) } @_;
    return @missing && (to_scalar($class, 0)." has no methods ".join ", ", @missing);
}, list => 1, export => 1;

=head2 isa_ok

=cut

build_refute isa_ok => \&_isa_ok, args => 2, export => 1;

build_refute new_ok => sub {
    my ($class, $args, $target) = @_;

    croak ("new_ok(): at least one argument must be present")
        unless defined $class;
    croak ("new_ok(): too many arguments")
        if @_ > 3;

    $args   ||= [];
    $class  = ref $class || $class;
    $target ||= $class;

    return "Not a class: ".to_scalar($class, 0)
        unless UNIVERSAL::can( $class, "can" );
    return "Class has no 'new' method: ".to_scalar( $class, 0 )
        unless $class->can( "new" );

    return _isa_ok( $class->new( @$args ), $target );
}, list => 1, export => 1;

sub _isa_ok {
    my ($obj, $class) = @_;

    croak 'isa_ok(): No class supplied to check against'
        unless defined $class;
    return "undef is not a $class" unless defined $obj;
    $class = ref $class || $class;

    if (
        (UNIVERSAL::can( $obj, "isa" ) && !$obj->isa( $class ))
        || !UNIVERSAL::isa( $obj, $class )
    ) {
        return to_scalar( $obj, 0 ) ." is not a $class"
    };
    return '';
};

=head2 contract_is $contract, "signature", ["message"]

Check that a contract has been executed to exactly the specified extent.

Signature format is "[01]*d", where t is just there to avoid accidental
numeric comparison, string of 01's represents individual tests, and 'd'
appears if no more tests may be performed (i.e. done_testing called).

B<EXPERIMENTAL>. The signature MAY change in the future.

=cut

build_refute contract_is => sub {
    my ($c, $condition) = @_;

    # the happy case first
    my $not_ok = $c->get_failed;
    my @out = map { $not_ok->{$_} ? 0 : 1 } 1..$c->get_count;
    return ''
        if $condition eq join "", @out;

    # analyse what went wrong - it did if we're here
    my @cond = split / *?/, $condition;
    my @fail;
    push @fail, "Contract signature: @out";
    push @fail, "Expected:           @cond";
    push @fail, sprintf "Tests executed: %d of %d", scalar @out, scalar @cond
        if @out != @cond;
    for (my $i = 0; $i<@out && $i<@cond; $i++) {
        next if $out[$i] eq $cond[$i];
        my $n = $i + 1;
        push @fail, "Unexpected " .($not_ok->{$n} ? "not ok $n" : "ok $n");
        if ($not_ok->{$n}) {
            push @fail, map { "DIAG # $_" } split /\n+/, $not_ok->{$n}[1]
        };
    };

    croak "Impossible: contract_is broken. File a bug in Test::Contract immediately!"
        if !@fail;
    return join "\n", @fail;
}, args => 2, export => 1;

1;
