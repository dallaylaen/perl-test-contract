package Test::Contract::Unit::Fake;

use strict;
use warnings;
our $VERSION = 0.03;

=head1 NAME

Test::Contract::Unit::Fake - Test::More compatibility test for Test::Contract

=head1 STOP!

This module pretends to load L<Test::More>, which it doesn't.
It is only here to test how Test::Contract::Unit
behaves in place of Test::More
without having to rewrite lot of test scripts.

=head1 METHODS

=cut

use Carp;

sub import {
    my $self = shift;
    if ($_[0] eq 'more') {
        $self->fake_test_more;
    } elsif (@_) {
        croak "$self->import(): Unknown arguments";
    };
};

=head2 fake_test_more

Try to detect real Test::More and Test::Simple.
If none are found, replace them with L<Test::Contract::Unit>
and change %INC accordingly.

If L<Test::Builder> is detected later, complain about it.

=cut

my $do_fake;

sub fake_test_more {
    return if $do_fake;
    if (Test::More->can("ok") or Test::Simple->can("ok")) {
        # TODO just die here?
        carp __PACKAGE__.": Test::More already loaded, avoid faking Test::More";
    } else {
        if (Test::Builder->can("new")) {
            carp __PACKAGE__.": Test::Builder already loaded, avoid faking Test::More";
        } else {
            # Do the fake loading

            require Test::Contract::Unit;

            _pretend( 'Test::Contract::Unit', 'Test::More' );
            $INC{"Test/More.pm"} = __FILE__;

            _pretend( 'Test::Contract::Unit', 'Test::Simple' );
            $INC{"Test/Simple.pm"} = __FILE__;

            $do_fake++;
        };
    };
};

sub _pretend {
    my ($src, $dst) = @_;

    no strict 'refs'; ## no critic
    @{$dst.'::EXPORT'} = @{$src.'::EXPORT'};
    *{$dst.'::'.$_} = \&{$src.'::'.$_}
        for @{$src.'::EXPORT'}, 'import';
};

# If some other module loaded Test::More, we're toast.
# At least complain about it...
END {
    carp __PACKAGE__.": Real Test::More loaded, the script MAY misbehave"
        if $do_fake and Test::Builder->can("new");
};

1;
