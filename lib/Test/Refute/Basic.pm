package Test::Refute::Basic;

use strict;
use warnings;

use parent qw(Exporter);
use Test::Refute::Engine qw(build_refute);

our @EXPORT_OK;
if (!@EXPORT_OK) {
    # build basic stuff

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
}; # end (if !@EXPORT)

1;
