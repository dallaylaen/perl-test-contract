package Test::Refute::Build;

use strict;
use warnings;
our $VERSION = 0.0103;

use Carp;
use parent qw(Exporter);
our @EXPORT = qw(build_refute refute_engine);

=head2 build_refute

=cut

my %Backend;
my %Carp_not;
my $trash_can = __PACKAGE__."::generated::For::Cover::To::See";

sub build_refute(@) {
    my ($name, $cond, %opt) = @_;

    my $class = "Test::Refute::Engine";

    if (my $backend = ( $class->can($name) ? $class : $Backend{$name} ) ) {
        croak "build_refute(): '$name' already registered by $backend";
    };

    my $target = $opt{target} || caller;

    my $nargs = $opt{args} || 0;

    my $method  = sub {
        my $self = shift;
        my $message = pop unless @_ <= $nargs;

        return $self->refute( $cond->(@_), $message );
    };
    my $wrapper = sub {
        my $message = pop unless @_ <= $nargs;
        return refute_engine()->refute( $cond->(@_), $message );
    };

    $Backend{$name}   = $target;
    my $todo_carp_not = !$Carp_not{ $target }++;
    my $todo_create   = !$opt{no_create};
    my $export        = $opt{export} ? "EXPORT" : $opt{export_ok} ? "EXPORT_OK" : "";

    no strict 'refs';
    *{ $class."::$name" } = $method;
    # FIXME UGLY HACK - somehow it makes Devel::Cover see the code in report
    *{ $trash_can."::$name" } = $cond;
    if ($todo_create) {
        *{ $target."::$name" } = $wrapper;
        push @{ $target."::".$export }, $name
            if $export;
    };
    if ($todo_carp_not) {
        no warnings 'once';
        push @{ $target."::CARP_NOT" }, __PACKAGE__, $class;
    };

    return 1;
};

=head2 refute_engine

Returns current default engine, dies if none right now.

=cut

my @stack;

sub refute_engine() {
    @stack or croak [caller]->[3]."(): Not currently testing anything";
    return $stack[-1];
};

sub refute_engine_push {
    my $eng = shift;
    $eng->isa( "Test::Refute::Engine" )
        or croak( "refute_engine_push(): won't load anything but Test::Refute::Engine" );
    push @stack, $eng;
};

sub refute_engine_cleanup {
    while (@stack and $stack[-1]->is_done) {
        pop @stack;
    };
    return;
};

1;
