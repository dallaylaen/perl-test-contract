package Test::Refute::TAP;

use strict;
use warnings;
our $VERSION = 0.0109;

=head1 NAME

Test::Refute::TAP - Test Anything Protocol driver for Test::Refute

=head1 DESCRIPTION

This class provides compatibility with L<TAP::Harness> and C<prove>,
allowing to use L<Test::Refute> as a L<Test::More> replacement.

This class is a L<Test::Refute::Contract> descendant.
It is automatically instantiated by Test::Refute when you load it,
so  that unit tests work.

=head1 METHODS

=cut

use Carp;
use parent qw(Test::Refute::Contract);

=head2 new( %options )

%options may include:

=over

=item * fd - file handle to print TAP to. Default is of course STDOUT.

=back

=cut

sub new {
    my ($class, %opt) = @_;

    # dup2 STDOUT so that we aren't botched by furthe redirect
    my $fd = delete $opt{fd} || \*STDOUT;
    open (my $dup, ">&", $fd)
        or die "redirect failed: $!";

    $opt{out} = $fd;
    $opt{count} = 0;

    return bless \%opt, $class;
};

sub _log {
    my ($self, $mess) = @_;

    $mess =~ s#\n+$##s;
    my $fd = $self->{out};
    print $fd "$mess\n";
};

=head2 get_tap

Since the TAP output is printed, it's not saved in the object.

So trying to get it back would result in exception...

=cut

sub get_tap {
    croak "get_tap(): TAP already printed, not saved";
};

1;

