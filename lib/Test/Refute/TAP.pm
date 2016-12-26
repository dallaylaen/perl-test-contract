package Test::Refute::TAP;

use strict;
use warnings;
our $VERSION = 0.01;

use parent qw(Test::Refute::Engine);

sub new {
    my ($class, %opt) = @_;

    my $fd = delete $opt{fd} || \*STDOUT;
    open (my $dup, ">&", $fd)
        or die "redirect failed: $!";

    $opt{out} = $dup;
    $opt{count} = 0;

    return bless \%opt, $class;
};

sub on_pass {
    my ($self, $test) = @_;

    print "ok $self->{count} - $test\n";
};

sub on_fail {
    my ($self, $test) = @_;
    
    my $fd = $self->{out};
    print $fd "not ok $self->{count} - $test\n";
    $self->diag( "Failed test '$test'" );
    $self->diag( Carp::shortmess( "" ) );
};

sub note {
};

sub diag {
    my ($self, $msg) = @_;

    my $fd = $self->{out};
    print $fd "# $_\n" for split /\n/, $msg;
};

sub on_done {
    my $self = shift;
    my $fd = $self->{out};
    print $fd "1..$self->{count}";
};

sub DESTROY {
};

1;

