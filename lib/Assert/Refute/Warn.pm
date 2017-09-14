package Assert::Refute::Warn;

use strict;
use warnings;
our $VERSION = 0.0301;

=head1 NAME

Assert::Refute::Warn - make sure a BLOCK warns exactly as expected

=head1 SYNOPSIS

    use Test::More;
    use Assert::Refute::Warn;

    warns_like {
        warn "food";
        warb "bard";
    } [qr/foo/, qr/bar/];

    done_testing;

=head1 FUNCTIONS

All functions here are exported by default.

=cut

use Exporter qw(import);

use Assert::Refute::Engine::Build;

=head2 warns_like { CODE; } ["warn", qr/or warn/], "Explanation";

Check that a code block warns in exactly the specified manner.

Unexpected number of warnings, failure to match patterns, or changed order
would all result in a failing test.

This code works by setting C<$SIG{__WARN__}>, so if the code under test
does it as well this won't work.

=cut

build_refute warns_like => sub {
    my ($code, $rex) = @_;

    $rex ||= [];

    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    eval { $code->(); 1 }
        or return "warns_like{}: unhandled exception: $@";

    if (@warn == @$rex) {
        my @bad;
        for( my $i = 0; $i < @$rex; $i++ ) {
            $warn[$i] =~ /$rex->[$i]/
                or push @bad, "Warning[$i] '$warn[$i]' doesn't match qr/$rex->[$i]/";
        };
        return join "\n", @bad;
    } else {
        return sprintf "Got %u warnings when %u expected; warns:\n%s",
            scalar @warn, scalar @$rex, join "\n", @warn;
    };
}, block => 1, args => 1, export => 1;

1;
