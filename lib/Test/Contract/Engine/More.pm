package Test::Contract::Engine::More;

use strict;
use warnings;
our $VERSION = 0.0208;

=head1 NAME

Test::Contract::Engine::More - Test::Contract backend compatible with Test::More

=head1 DESCRIPTION

This module allows Test::Contract tests to play nice with Test::More and friends.

=cut

use Carp;
use Test::Builder;

use parent qw(Test::Contract::Engine);

sub _NEWOPTIONS { return __PACKAGE__->SUPER::_NEWOPTIONS, qw(test_builder) };

=head2 new( %options )

Options may include:

test_builder - a custom Test::Builder object or its substitute.

=cut

sub new {
    my ($class, %opt) = @_;

    $opt{test_builder} ||= Test::Builder->new;
    return $class->SUPER::new(%opt);
};

=head2 refute( $condition, $message )

See L<Test::Contract::Engine>. This is L<Test::Builder>-based implementation.

=cut

sub refute {
    my ($self, $cond, $mess) = @_;

    local $Test::Builder::Level = $Test::Builder::Level
        + (caller()->isa("Test::Contract") ? 2 : 1);

    if ($cond) {
        # something not right
        $self->{test_builder}->ok( 0, $mess );
        $self->{test_builder}->diag( $cond )
            unless looks_like_number( $cond );
        return '';
    } else {
        return $self->{test_builder}->ok( 1, $mess );
    };
};

=head2 diag

=cut

sub diag {
    my ($self, @mess) = @_;

    $self->{test_builder}->diag(
        map { defined $_ && !ref $_ ? $_ : to_scalar($_); } @mess
    );
};

=head2 note

Both copy-pasted from parent, with Test::Builder added inside.

=cut

sub note {
    my ($self, @mess) = @_;

    $self->{test_builder}->note(
        map { defined $_ && !ref $_ ? $_ : to_scalar($_); } @mess
    );
};

=head2 bail_out

Goto BAIL_OUT.

=cut

sub bail_out {
    my ($self, $reason) = @_;

    $self->{test_builder}->BAIL_OUT( $reason );
};

=head1 GETTERS

=head2 get_passing

=head2 get_count

=head2 get_error_count

=cut

sub get_passing {
    my $self = shift;
    return $self->{test_builder}->is_passing;
};

sub get_count {
    my $self = shift;
    return $self->{test_builder}->current_test;
};

sub get_error_count {
    my $self = shift;
    return scalar keys %{ $self->get_failed };
};

=head2 get_failed

Is a stub so far... Only numbers retained.

=cut

sub get_failed {
    my $self = shift;
    my %hash;

    my @summary = $self->{test_builder}->summary;
    for (my $i = 0; $i<@summary; $i++) {
        $hash{$i+1}++ unless $summary[$i];
    };
    return \%hash;
};

=head2 get_done

Stub since Test::Builder has no way to tell.

=cut

sub get_done {
    return 0;
};

1;
