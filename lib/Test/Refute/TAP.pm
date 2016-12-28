package Test::Refute::TAP;

use strict;
use warnings;
our $VERSION = 0.0107;

use Carp;
use parent qw(Test::Refute::Contract);

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

    my $fd = $self->{out};
    print $fd "$mess\n";
};

sub get_tap {
    croak "get_tap(): TAP already printed, not saved";
};

1;

