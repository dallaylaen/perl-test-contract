package Test::Refute::Deep;

use strict;
use warnings;
our $VERSION = 0.0102;

=head1 NAME

Test::Refute::Deep - is_deeply method for Test::Refute suite.

=head1 DESCRIPTION

Add C<is_deeply> method to L<Test::Refute> and L<Test::Refute::Contract>.

=cut

use Scalar::Util qw(blessed refaddr looks_like_number);
use parent qw(Exporter);

use Test::Refute::Build;

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

    # diff refs => isn't right away
    if (ref $old ne ref $new) {
        return join "!=", to_scalar($old), to_scalar($new);
    };

    # not deep - return right away
    if (ref $old ne 'HASH' and ref $old ne 'ARRAY') {
        $old = to_scalar($old);
        $new = to_scalar($new);

        return $old ne $new && "$old!=$new",
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

    if (ref $old eq 'ARRAY') {
        my @diff;
        for (my $i = 0; $i < @$old || $i < @$new; $i++ ) {
            my $off = deep_diff( $old->[$i], $new->[$i], $known, $path."[$i]" );
            push @diff, "$i:$off" if $off;
        };
        return @diff ? _array2str( \@diff ) : '';
    };
    if (ref $old eq 'HASH') {
        my ($both_k, $old_k, $new_k) = _both_keys( $old, $new );
        my %diff;
        $diff{$_} = to_scalar( $old->{$_} )."!=(none)" for @$old_k;
        $diff{$_} = "(none)!=".to_scalar( $new->{$_} ) for @$new_k;
        foreach (@$both_k) {
            my $off = deep_diff( $old->{$_}, $new->{$_}, $known, $path."{$_}" );
            $diff{$_} = $off if $off;
        };
        return %diff ? _hash2str( \%diff ) : '';
    };

    die "This point should never be reached, report bug immediately";
};

sub _hash2str {
    my $hash = shift;
    return "{".join(", ", map { to_scalar($_).":$hash->{$_}" } sort keys %$hash)."}";
};

sub _array2str {
    my $array = shift;
    return "[".join(", ", @$array)."]";
};

=head2 to_scalar ( [] || {} || "string" || undef )

Convert an unknown data type to a human-readable string.

Hashes/arrays are only penetrated 1 level deep.

undef is returned as C<(undef)> so it can't be confused with other types.

Strings are quoted unless numeric.

Refs returned as "My::Module/1a2c3f

=cut

my %replace = ( "\n" => "n", "\\" => "\\", '"' => '"', "\0" => "0", "\t" => "t" );
sub to_scalar {
    my ($data, $skip_deep) = @_;

    return '(undef)' unless defined $data;
    if (!ref $data) {
        return $data if looks_like_number($data);
        $data =~ s/([\0"\n\t\\])/\\$replace{$1}/g;
        $data =~ s/([^\x20-\xFF])/sprintf "\\x%02x", ord $1/ge;
        return "\"$data\"";
    };
    if (!$skip_deep) {
        if (ref $data eq 'ARRAY') {
            return "[".join(", ", map { to_scalar($_, 1) } @$data )."]";
        };
        if (ref $data eq 'HASH') {
            return "{".join(", ", map {
                 to_scalar($_) .":".to_scalar( $data->{$_}, 1 );
            } sort keys %$data )."}";
        };
    };
    return sprintf "%s/%x", ref $data, refaddr $data;
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
