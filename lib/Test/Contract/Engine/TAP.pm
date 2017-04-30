package Test::Contract::Engine::TAP;

use strict;
use warnings;
our $VERSION = 0.03;

=head1 NAME

Test::Contract::Engine::TAP - Test Anything Protocol driver for Test::Contract

=head1 DESCRIPTION

This class provides compatibility with L<TAP::Harness> and C<prove>,
allowing to use L<Test::Contract> as a L<Test::More> replacement.

This class is a L<Test::Contract> descendant.
It is automatically instantiated by Test::Contract when you load it,
so  that unit tests work.

=head1 METHODS

=cut

use Carp;
use parent qw(Test::Contract);

=head2 new( %options )

%options may include:

=over

=item * out - file handle to print TAP to. Default is of course STDOUT.

=item * indent - indent output (useful for subtests).

=back

=cut

sub new {
    my ($class, %opt) = @_;

    # dup2 STDOUT so that we aren't botched by further redirect
    my $fd = $opt{out} || \*STDOUT;
    croak "Cannot use closed filehandle for $class->new:out"
        unless $fd and defined fileno $fd;
    if (fileno $fd > 0) {
        # HACK - avoid duping an in-memory ">\$var"
        open (my $dup, ">&", $fd)
            or croak "redirect failed: $!";
        $opt{out}     = $dup;
    };

    my $self = $class->SUPER::new( %opt );
    $self->{indent_cache} = '    ' x $self->get_indent;

    return $self;
};

sub _NEWOPTIONS {
    my $self = shift;
    return $self->SUPER::_NEWOPTIONS, qw(out);
};

sub _log {
    my ($self, $mess) = @_;

    my $fd = $self->{out};
    return unless $fd;
    $mess =~ s#\n+$##s;
    print $fd "$self->{indent_cache}$mess\n";
};

=head2 done_testing

Not only outputs plan, but also closes fh if needed.

=cut

sub done_testing {
    my $self = shift;
    my $ret = $self->SUPER::done_testing(@_);
    delete $self->{out}; # will autoclosed if last
    return $ret;
};

=head2 get_tap

Since the TAP output is printed, it's not saved in the object.

However, it may be reconstructed to some extent...

=cut

sub get_tap {
    my ($self, $verb) = @_;

    my @result;
    my $fails = $self->get_failed;

    foreach my $n (1 .. $self->get_count) {
        my $fail_pair = $fails->{$n};
        if (!$fail_pair) {
            push @result, "ok $n";
            next;
        };

        push @result , "not ok $n"
            .( $fail_pair->[0] ? " - $fail_pair->[0]" : '' );

        if ($verb && !looks_like_number($fail_pair->[1])) {
            push @result, map { "# $_" } split "\n", $fail_pair->[1];
        };
    };
    push @result, $self->{bail_out}
        ? "Bail out! $self->{bail_out}"
        : "1..".$self->get_count;

    return join "\n", @result, '';
};

=head2 get_handle_out

Returns the handle used for output.

=cut

sub get_handle_out {
    my $self = shift;
    return $self->{out};
};

=head2 set_mute

=cut

sub set_mute {
    my $self = shift;
    delete $self->{out};
    return $self->SUPER::set_mute(@_);
};

1;

