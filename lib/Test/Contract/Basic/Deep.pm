package Test::Contract::Basic::Deep;

use strict;
use warnings;
our $VERSION = 0.0206;

=head1 NAME

Test::Contract::Basic::Deep - is_deeply method for Test::Contract suite.

=head1 DESCRIPTION

Add C<is_deeply> method to L<Test::Contract> and L<Test::Contract>.

=cut

use Scalar::Util qw(refaddr);
use parent qw(Exporter);

use Test::Contract::Engine::Build;

our @EXPORT_OK = qw(deep_diff);

=head2 is_deeply( $got, $expected )

=cut

build_refute is_deeply => sub {
    my $diff = deep_diff( shift, shift );
    return unless $diff;
    return "Structures differ (got != expected):\n$diff";
}, export => 1, args => 2;


=head2 deep_diff( $old, $new )

Returns a true scalar if structure

=cut

sub deep_diff {
    my ($old, $new, $known, $path) = @_;

    $known ||= {};
    $path ||= '&';

    # TODO combine conditions, too much branching
    # diff refs => isn't right away
    if (ref $old ne ref $new or (defined $old xor defined $new)) {
        return join "!=", to_scalar($old), to_scalar($new);
    };

    # not deep - return right away
    return '' unless defined $old;
    if (!ref $old) {
        return $old ne $new && join "!=", to_scalar($old), to_scalar($new),
    };

    # recursion
    # check topology first to avoid looping
    # new is likely to be simpler (it is the "expected" one)
    # FIXME BUG here - if new is tree, and old is DAG, this code won't catch it
    if (my $new_path = $known->{refaddr $new}) {
        my $old_path = $known->{-refaddr($old)};
        return to_scalar($old)."!=$new_path" unless $old_path;
        return $old_path ne $new_path && "$old_path!=$new_path";
    };
    $known->{-refaddr($old)} = $path;
    $known->{refaddr $new} = $path;

    if (UNIVERSAL::isa( $old , 'ARRAY') ) {
        my @diff;
        for (my $i = 0; $i < @$old || $i < @$new; $i++ ) {
            my $off = deep_diff( $old->[$i], $new->[$i], $known, $path."[$i]" );
            push @diff, "$i:$off" if $off;
        };
        return @diff ? _array2str( \@diff, ref $old ) : '';
    };
    if (UNIVERSAL::isa( $old, 'HASH') ) {
        my ($both_k, $old_k, $new_k) = _both_keys( $old, $new );
        my %diff;
        $diff{$_} = to_scalar( $old->{$_} )."!=(none)" for @$old_k;
        $diff{$_} = "(none)!=".to_scalar( $new->{$_} ) for @$new_k;
        foreach (@$both_k) {
            my $off = deep_diff( $old->{$_}, $new->{$_}, $known, $path."{$_}" );
            $diff{$_} = $off if $off;
        };
        return %diff ? _hash2str( \%diff, ref $old ) : '';
    };

    # finally - don't know what to do, compare refs
    $old = to_scalar($old);
    $new = to_scalar($new);
    return $old ne $new && join "!=", $old, $new;
};

sub _hash2str {
    my ($hash, $type) = @_;
    $type = '' if $type eq 'HASH';
    return $type.'{'
            . join(", ", map { to_scalar($_).":$hash->{$_}" } sort keys %$hash)
        ."}";
};

sub _array2str {
    my ($array, $type) = @_;
    $type = '' if $type eq 'ARRAY';
    return "$type\[".join(", ", @$array)."]";
};

# in: hash + hash
# out: common keys +
sub _both_keys {
    my ($old, $new) = @_;
    # TODO write shorter
    my %uniq;
    $uniq{$_}++ for keys %$new;
    $uniq{$_}-- for keys %$old;
    my (@o_k, @n_k, @b_k);
    foreach (sort keys %uniq) {
        if (!$uniq{$_}) {
            push @b_k, $_;
        }
        elsif ( $uniq{$_} < 0 ) {
            push @o_k, $_;
        }
        else {
            push @n_k, $_;
        };
    };
    return (\@b_k, \@o_k, \@n_k);
};

1;
