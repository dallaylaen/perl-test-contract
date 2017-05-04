package Test::Contract::Engine::Build;

use strict;
use warnings;
our $VERSION = 0.0302;

=head1 NAME

Test::Contract::Engine::Build - tool for extending Test::Contract suite

=head1 DESCRIPTION

Unfortunately, extending L<Test::Contract> is not completely straightforward.

In order to create a new test function, one needs to:

=over

=item * provide a check function that returns a false value on success
and a brief description of the problem on failure
(e.g. C<"$got != $expected">);

=item * build an exportable wrapper around it that would talk to
the most up-to-date L<Test::Contract> instance;

=item * add a method with the same name to L<Test::Contract>
so that object-oriented and functional interfaces
are as close to each other as possible.

=back

The first task still has to be done by a programmer (you),
but the other two can be more or less automated.
Hence this module.

=head1 SINOPSYS

Extending the test suite goes as follows:

    package My::Package;
    use Test::Contract::Engine::Build;
    use parent qw(Exporter);

    build_refute is_everything => sub {
        return if $_[0] == 42;
        return "$_[0] is not answer to life, universe, abd everything";
    }, export => 1, args => 1;

    1;

This can be later used either inside production code to check a condition:

    use Test::Contract;
    use My::Package;
    my $c = contract {
        is_everything( $foo );
        $_[0]->is_everything( $bar ); # ditto
    };
    # ... check $c validity

or in a test script:

    use Test::More;
    use My::Package;
    is_everything $foo, "Check for answer";
    done_testing;

The function provided to builder MUST return a false value if everything is ok,
or some details (but generally any true value) if not.

This call will create a prototyped function is_everything(...) in the calling
package, with C<args> positional parameters and an optional human-readable
message. (Think C<ok 1>, C<ok 1 'test passed'>).

Such function will perform the check under both Test::Contract and
L<Test::More>.

=head1 FUNCTIONS

All functions are exportable.

=cut

use Carp;
use Scalar::Util qw(weaken blessed set_prototype looks_like_number refaddr);
use parent qw(Exporter);
our @EXPORT = qw(build_refute contract_engine to_scalar);
our @EXPORT_OK = qw(contract_engine_push contract_engine_cleanup);

=head2 build_refute name => CODE, %options

Create a function in calling package and a method in L<Test::Contract>.
As a side effect, Test::Contract's internals are added to the caller's
C<@CARP_NOT> array so that carp/croak points to actual outside usage.

B<NOTE> One needs to use Exporter explicitly if either C<export>
or C<export_ok> option is in use. This MAY change in the future.

Options may include:

=over

=item * export => 1    - add function to @EXPORT
(Exporter still has to be used by target module explicitly).

=item * export_ok => 1 - add function to @EXPORT_OK (don't export by default).

=item * no_create => 1 - don't generate a function at all, just add to
L<Test::Contract>'s methods.

=item * args => nnn - number of arguments. This will prototype function
to accept nnn scalars + optional descripotion.

=item * list => 1 - create a list prototype instead.
Mutually exclusive with args.

=item * block => 1 - create a block function.

=item * no_proto => 1 - skip prototype, function will have to be called
with parentheses.

=back

=cut

my %Backend;
my %Carp_not;
my $trash_can = __PACKAGE__."::generated::For::Cover::To::See";
my %known;
$known{$_}++ for qw(args list block no_proto
    export export_ok no_create);

sub build_refute(@) { ## no critic # Moose-like DSL for the win!
    my ($name, $cond, %opt) = @_;

    my $class = "Test::Contract";

    if (my $backend = ( $class->can($name) ? $class : $Backend{$name} ) ) {
        croak "build_refute(): '$name' already registered by $backend";
    };
    my @extra = grep { !$known{$_} } keys %opt;
    croak "build_refute(): unknown options: @extra"
        if @extra;
    croak "build_refute(): list and args options are mutually exclusive"
        if $opt{list} and defined $opt{args};

    my $target = $opt{target} || caller;

    my $nargs = $opt{args} || 0;
    $nargs = 9**9**9 if $opt{list};

    $nargs++ if $opt{block};

    # TODO Add executability check if $block
    my $method  = sub {
        my $self = shift;
        my $message; $message = pop unless @_ <= $nargs;

        return $self->refute( scalar $cond->(@_), $message );
    };
    my $wrapper = sub {
        my $message; $message = pop unless @_ <= $nargs;
        return contract_engine()->refute( scalar $cond->(@_), $message );
    };
    if (!$opt{no_proto} and ($opt{block} || $opt{list} || defined $opt{args})) {
        my $proto = $opt{list} ? '@' : '$' x ($opt{args} || 0);
        $proto = "&$proto" if $opt{block};
        $proto .= ';$' unless $opt{list};

        # '&' for set_proto to work on a scalar, not {CODE;}
        &set_prototype( $wrapper, $proto );
    };

    $Backend{$name}   = $target; # just for the record
    my $todo_carp_not = !$Carp_not{ $target }++;
    my $todo_create   = !$opt{no_create};
    my $export        = $opt{export} ? "EXPORT" : $opt{export_ok} ? "EXPORT_OK" : "";

    # Magic below, beware!
    no strict 'refs'; ## no critic # really need magic here

    # set up method for OO interface
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

    # magic ends here

    return 1;
};

=head2 contract_engine

Returns the L<Test::Contract> instance performing tests at the moment.

If there's none, an exception is thrown. As an exception,
if Test::Builder is detected an engine will be created on the fly.

=cut

my @stack;

sub contract_engine() { ## no critic
    if (!@stack) {
        if ( Test::Builder->can("new") and Test::Builder->can("ok")) {
            eval {
                require Test::Contract::Engine::More;
                push @stack, Test::Contract::Engine::More->new;
                1;
            } and return $stack[-1];
            carp "Failed to load Test::Builder-compatible backend: $@";
        };
        croak "FATAL: Test::Contract: Not currently testing anything";
    };
    return $stack[-1];
};

=head2 contract_engine_push( $contract )

Make C<$contract> the default engine until it's detroyed, or done_testing is
called. This is useful for stuff like subtests.
As the name suggests, may be called multiple times, creating a stack.

C<$contract> must be a L<Test::Contract> descendant.

If C<$contract> goes out of scope, it is automatically removed from the stack.
(See C<weaken> in L<Scalar::Util>).

Maybe it's better to avoid this call in favor of safer C<contract> in
sibling modules, unless there's a reason.

Not exported by default.

=cut

sub contract_engine_push {
    my $eng = shift;
    blessed $eng and $eng->isa( "Test::Contract" )
        or croak( "contract_engine_push(): won't load anything but Test::Contract" );
    push @stack, $eng;
    weaken $stack[-1];
    return scalar @stack;
};

=head2 contract_engine_cleanup

Remove all finished contracts from engine stack.
This is called by both C<done_testing> and contract's destructor.

Maybe it's better to avoid this call in favor of safer C<contract> in
sibling modules, unless there's a reason.

Not exported by default.

=cut

sub contract_engine_cleanup {
    while (@stack and (!$stack[-1] or $stack[-1]->get_done)) {
        pop @stack;
    };
    return scalar @stack;
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
    my ($data, $depth) = @_;
    $depth = 1 unless defined $depth;

    return '(undef)' unless defined $data;
    if (!ref $data) {
        return $data if looks_like_number($data);
        $data =~ s/([\0"\n\t\\])/\\$replace{$1}/g;
        $data =~ s/([^\x20-\xFF])/sprintf "\\x%02x", ord $1/ge;
        return "\"$data\"";
    };
    if ($depth) {
        if (UNIVERSAL::isa($data, 'ARRAY')) {
            return (ref $data eq 'ARRAY' ? '' : ref $data)
                ."[".join(", ", map { to_scalar($_, $depth-1) } @$data )."]";
        };
        if (UNIVERSAL::isa($data, 'HASH')) {
            return (ref $data eq 'HASH' ? '' : ref $data)
            . "{".join(", ", map {
                 to_scalar($_, 0) .":".to_scalar( $data->{$_}, $depth-1 );
            } sort keys %$data )."}";
        };
    };
    return sprintf "%s/%x", ref $data, refaddr $data;
};

=head2 contract_engine_init

If Test::Contract engine stack is empty, create an engine assuming we're
in a test script. A L<Test::More> compatibility layer will be loaded
if needed.

B<NOTE> Dangerous. This function, although safe, is mostly for internal usage.

=cut

my $main_engine;
my $main_pid = 0;

sub contract_engine_init {
    return if $main_engine and $main_pid == $$;

    if (Test::Builder->can("ok")) {
        require Test::Contract::Engine::More;
        $main_engine = Test::Contract::Engine::More->new;
    } else {
        require Test::Contract::Engine::TAP;
        $main_engine = Test::Contract::Engine::TAP->new;
    };
    $main_engine->start_testing;
    $main_pid = $$;
};

END {
    if ($main_engine and $main_engine->isa("Test::Contract::Engine::TAP") and $main_pid == $$) {
        carp "Test::More loaded by accident, but Test::Refute is not in compat mode!"
            if Test::Builder->can("ok");
        if ($main_engine->get_count) {
            croak "[$$] done_testing was not seen"
                unless $main_engine->get_plan;

            $main_engine->done_testing
                unless $main_engine->get_done;

            my $ret = $main_engine->get_error_count;
            $ret = 100 if $ret > 100;
            $? = $ret;
        }
        elsif ($main_engine->get_skipped) {
            $main_engine->done_testing
                unless $main_engine->get_done;
        };
    };
};

1;
