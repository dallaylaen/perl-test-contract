package Test::Refute::TAP;

use strict;
use warnings;
our $VERSION = 0.0111;

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

=item * out - file handle to print TAP to. Default is of course STDOUT.

=item * indent - indent output (useful for subtests).

=back

=cut

sub new {
    my ($class, %opt) = @_;

    # dup2 STDOUT so that we aren't botched by furthe redirect
    my $fd = delete $opt{out} || \*STDOUT;
    open (my $dup, ">&", $fd)
        or die "redirect failed: $!";

    $opt{out}     = $fd;
    $opt{count}   = 0;
    $opt{indent}  = ' ' x (($opt{indent}||0) * 4);

    return bless \%opt, $class;
};

sub _NEWOPTIONS {
    my $self = shift;
    return $self->SUPER::_NEWOPTIONS, qw(out);
};

sub _log {
    my ($self, $mess) = @_;

    $mess =~ s#\n+$##s;
    my $fd = $self->{out};
    print $fd "$self->{indent}$mess\n";
};

=head2 get_indent

=cut

sub get_indent {
    my $self = shift;
    return (length $self->{indent}) / 4;
};

=head2 get_tap

Since the TAP output is printed, it's not saved in the object.

However, it may be reconstructed to some extent...

=cut

sub get_tap {
    my $self = shift;

    my @result = ("1..".$self->test_number);

    my $fails = $self->get_failed;

    foreach my $n (1 .. $self->test_number) {
        my $f = $fails->{$_};
        push @result, $f
            ? ("not ok $n - $f->[0]", map { "# $_" } split "\n", $f->[1])
            : "ok $n";
    };

    return join "\n", @result, '';
};

1;

