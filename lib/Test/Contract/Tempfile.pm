package Test::Contract::Tempfile;

use strict;
use warnings;
our $VERSION = 0.0205;

=head1 NAME

Test::Contract::Tempfile - self-destructing temporary files for Test::Contract

=head1 DESCRIPTION

Creates a temporary file that self-destructs on successful test completion,
warns its name otherwise.

=cut

use Carp;
use Scalar::Util qw(weaken);
use File::Temp qw(tempfile tempdir);
use parent qw(Exporter);

use Test::Contract::Build;

our @EXPORT_OK = qw(mktemp);

=head2 mktemp()

Return temp file, will be auto-deleted if current contract is completed.

=cut

sub mktemp {
    my ($tpl) = @_;

    return __PACKAGE__->new->get_file( $tpl );
};

=head2 new ( contract => ..., %options )

=cut

sub new {
    my ($class, %opt) = @_;

    $opt{contract} ||= refute_engine
        or croak "$class->new: contract option is required and must be a Test::Contract::Engine";

    my $self = bless { contract => $opt{contract} }, $class;

    weaken $self->{contract};
    return $self;
};

=head2 get_file( $tpl )

Get a new temp file.

=cut

sub get_file {
    my ($self, $tpl) = @_;

    if (!$self->{contract}) {
        carp "Contract finished, no more temp files";
        return;
    };

    $self->_register( $self->{contract} )
        unless $self->{registered};

    my ($fd, $file) = tempfile( $tpl );
    $self->{files}{$file}++;

    return wantarray ? ($fd, $file) : $fd;
};

=head2 cleanup

=cut

sub cleanup {
    my $self = shift;

    foreach (keys %{ $self->{files} }) {
        if (unlink $_ or $!{ENOENT}) {
            # if already deleted, no worry
            delete $self->{files}{$_};
            next;
        };
        # This is likely destructor, so don't die
        carp "Failed to unlink temp file '$_': $!";
    };
};

=head2 do_files( sub { ... } )

Apply given code ref to ALL known temp files.

=cut

sub do_files {
    my ($self, $code) = @_;

    foreach (keys %{ $self->{files} }) {
        $code->($_);
    };
    return $self;
};

sub _register {
    my ($self, $contract) = @_;
    $contract->set_done_callback( sub {
        my $c = shift;
        if ($c->get_finished and $c->get_passed) {
            $self->cleanup;
        } else {
            my @files = map { "'$_'" } keys %${ $self->{files} };
            carp "Tests failed, see temp files: @files";
        };
        undef $self;
    } );
    $self->{registered}++;

    return $self;
};

1;
