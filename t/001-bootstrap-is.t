#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    eval {
        require parent;
        require Carp;
        require Exporter;
        require Scalar::Util;
        require Test::Refute::Build;
        require Test::Refute::Basic::Is;
        Test::Refute::Basic::Is->import;
        1;
    } or do {
        print "Bail out! $@";
        exit 1;
    };
};

Test::Refute::Contract->can("import")
    and print "Bail out! Contract loaded by accident, redo bootstrapping\n";
Test::Refute::Basic->can("import")
    and print "Bail out! Basic loaded by accident, redo bootstrapping\n";

my @warn;
$SIG{__WARN__} = sub {
    push @warn, $_[0];
    warn $_[0];
};
{
    # Re-implement refute() paradigm by hand
    package My::Bootstrap;
    use Carp;
    our @ISA = qw(Test::Refute::Contract);
    our @CARP_NOT = qw(Test::Refute::Basic);

    sub new { bless {}, shift };

    # refute ( $cond, +$message ) - normal refute
    # refute ( $cond, -$message ) - deliberate failure
    sub refute {
        my ($self, $cond, $mess) = @_;
        $mess =~ /^([-+])/ or croak "Test message must start with + for pass, - for fail";
        $self->{n}++;
        my $fail = ($cond xor $1 eq '-');
        $self->{fail}++ if $fail;
        print( ($fail ? "not " : ""), "ok $self->{n} - $mess\n" );
        return !$fail;
    };
    sub is_done { 0; }; # run forever

    package Test::Refute::Contract;
    our $VERSION = 0;
};

my $contract = My::Bootstrap->new;

# Test bootstrap first
$contract->refute( 0, "+self-test" );
$contract->refute( 1, "-self-test" );

# Now join the party
Test::Refute::Build::refute_engine_push( $contract );

# Check "is" thoroughly
is ( 42, 42, "+is normal" );
is ( 42, 43, "-is normal" );

is ( "foo", "foo", "+is normal" );
is ( "foo", "bar", "-is normal" );

is ( undef, undef, "+is undef both" );
is ( undef, '', "-is undef 1" );
is ( '', undef, "-is undef 2" );

# Ok for now... Bootstrap contract next.
print "1..$contract->{n}\n";
print "Bail out! Bootstrapping failed\n"
    if $contract->{fail} || @warn;
exit( $contract->{fail}||0 );
