package Test::Refute::TAP;

use strict;
use warnings;
our $VERSION = 0.0104;

use parent qw(Test::Refute::Engine);

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

sub on_pass {
    my ($self, $test) = @_;

    my $fd = $self->{out};
    print $fd "ok $self->{count} - $test\n";
};

sub on_fail {
    my ($self, $test) = @_;
    
    my $fd = $self->{out};
    print $fd "not ok $self->{count} - $test\n";
    $self->diag( Carp::shortmess("Failed test '$test'") );
};

sub note {
    my ($self, $msg) = @_;

    my $fd = $self->{out};
    print $fd "## $_\n" for split /\n+/, $msg;
};

sub diag {
    my ($self, $msg) = @_;

    my $fd = $self->{out};
    print $fd "# $_\n" for split /\n+/, $msg;
};

sub on_done {
    my $self = shift;
    my $fd = $self->{out};
    print $fd "1..$self->{count}\n";
};

sub DESTROY {
};

1;

