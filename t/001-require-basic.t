#!/usr/bin/env perl

use strict;
use warnings;

# We must load Basic.pm first, before all else
# so that cover -t doesn't lie about coverage

use Test::Refute::Build;
use Test::Refute::Basic;

{
    package My::Bootstrap;
    use Carp;
    our @ISA = qw(Test::Refute::Engine);
    our @CARP_NOT = qw(Test::Refute::Basic);

    sub new { bless {}, shift };
    sub refute {
        my ($self, $cond, $mess) = @_;
        $mess =~ /^([-+])/ or croak "Test message must start with + for pass, - for fail";
        $self->{n}++;
        print( ($cond xor $1 eq '+') ? "" : "not " );
        print( "ok $self->{n} - $mess\n" );
    };
    sub is_valid {
        my $self = shift;
        return !$self->{result};
    };
    sub current_test {
        my $self = shift;
        return $self->{n} || 0;
    };
    sub is_done { 0; }; # forever

    package Test::Refute::Engine;
    our $VERSION = 0;
};

my $contract = My::Bootstrap->new;

Test::Refute::Build::refute_engine_push( $contract );

is ( 42, 42, "+is" );
is ( 42, 43, "-is" );

like ( 42, 4, "-like" );
like ( 42, '\d+', "+like" );

print "1..".$contract->current_test."\n";

