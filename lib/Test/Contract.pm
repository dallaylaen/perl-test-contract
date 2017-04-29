package Test::Contract;

use strict;
use warnings;
our $VERSION = 0.0210;

=head1 NAME

Test::Contract - Object-oriented testing and assertion tool

=head1 SYNOPSIS

    # Somewhere inside production codebase
    use Test::Contract;

    my $c = Test::Contract->new;
    $c->is ($foo, $bar, "Foo equals bar");
    $c->like ($user_input, qr/F?o?r?m?a?t/, "Input format as expected");
    if ($c->get_passing) {
        warn $c->get_tap;
    };

=head1 DESCRIPTION

Test::Contract can check sets of L<Test::More>-like conditions
without turning the whole application into a giant test script.

This may be useful when validating user input, loading plug-ins or external
modules, or checking that the code is error-free.

A counterpart method exists for ALL Test::More standard checks.

Also it is fairly simple to build custom conditions.

=cut

use Carp;
use Scalar::Util qw(looks_like_number);
use Exporter qw(import);

use Test::Contract::Engine::Build qw(to_scalar);

our @EXPORT_OK = qw(contract);
our @CARP_NOT = qw(Test::Contract::Engine::Build Test::Contract::Unit);
# preload most basic tests
require Test::Contract::Basic;
require Test::Contract::Basic::Deep;

=head1 OPTIONAL EXPORT

=head2 contract { CODE; };

=head2 contract { CODE; } $contract_instance;

Run a series of tests against a contract object, recording the output
for future analysis. See GETTERS below.
This is like C<subtest>, but way more powerful.

Said contract object is passed to CODE reference as first argument,
so that one can run assertions is production code without polluting
the global namespace.

These two are equivalent:

    use Test::Contract;

    my $contract = contract {
        is $foo, $baf, "foobar";
    };
    if ($contract->get_passing) {
        ...
    };

And

    use Test::Contract;

    my $contract = contract {
        my $c = shift;
        $c->is( $foo, $bar, "foobar" );
    };
    if ($contract->get_passing) {
        ...
    };

=cut

sub contract (&;$) { ## no critic # need block function
    my ($code, $engine) = @_;

    $engine ||= __PACKAGE__->new;
    $engine->start_testing;

    $code->($engine);
    $engine->done_testing
        unless $engine->get_done;
    return $engine;
};

=head1 METHODS

The generalized object-oriented interface for C<Test::Contract> goes below.

=head2 new(%options)

Options may include:

=over

=item * indent

=item * plan

=back

B<EXPERIMENTAL> These may change in the future.

=cut

sub new {
    my ($class, %opt) = @_;

    my $self;
    $self->{$_} = $opt{$_} for $class->_NEWOPTIONS;
    $self->{indent} ||= 0;

    bless $self, $class;
    $self->plan( $opt{plan} )
        if $opt{plan};

    return $self;
};

=head2 subcontract( %options )

Create a fresh copy of current contract.

Increase indent unless $option{indent} given.

=cut

sub subcontract {
    my ($self, %opt) = @_;

    my $class = delete $opt{class} || ref $self;
    my $name  = delete $opt{name}  || Carp::shortmess("Subcontract initiated");
    $name =~ s/\n+$//;

    $opt{indent} = $self->get_indent + 1
        unless exists $opt{indent};
    exists $opt{$_} or $opt{$_} = $self->{$_}
        for $self->_NEWOPTIONS;

    my $child = $class->new( %opt );
    $child->set_done_callback(sub {
        $self->refute( !$child->get_passing && $child->get_tap, $name);
    });

    return $child;
};

# TODO this is so horribly broken. Use fields? Use Moose?..
sub _NEWOPTIONS {
    return qw(indent);
};

=head2 refute( $condition, $name )

If condition is false, return truth, also calling C<on_pass()> method.
If condition is true, complain loudly,
also calling c<on_fail()> and C<diag()> methods.

This is the CORE of the whole L<Test::Refure> suite.

The point of this semantics inversion (relative to a normal C<assert>)
is that when everything is fine, no further information is needed.
However, when things do not work well, details may be helpful.

=cut

# TODO or should we swap args?
sub refute {
    my ($self, $deny, $message) = @_;

    croak "Already done testing"
        if $self->{done};

    return $deny ? 0 : $self->{count}
        if $self->{skip_all};

    $self->{count}++;

    if ($deny) {
        $self->{fails}++;
        $self->on_fail( $message, $deny );
        $self->diag( Carp::shortmess( "Failed: ".($message || $self->{count}) ));
        $self->diag( $deny )
            unless looks_like_number($deny) or ref $deny;
        return 0;
    };

    $self->on_pass( $message );
    return $self->{count};
};

=head2 start_testing

Push this engine onto the stack. All prototyped checks
will now be redirected to it.

=cut

sub start_testing {
    my $self = shift;

    $self->{count} and croak "start_testing() called after tests";
    Test::Contract::Engine::Build::contract_engine_push( $self );

    return $self;
};

=head2 plan( $n )

Commit to performing exactly n tests. This would die if testing had started.

=cut

sub plan {
    my ($self, $n) = @_;

    croak "plan(): argument must be numeric, not $n"
        unless $n =~ /^-?\d+$/;
    croak "plan(): testing already started"
        if $self->get_count;

    $self->{plan} = $n;
    return $self;
};

=head2 skip_all( "reason" )

reason must be true, or this won't work!

=cut

sub skip_all {
    my ($self, $reason) = @_;
    return if $self->get_done;
    $self->{skip_all} ||= $reason || 'unknown reason';
};

=head2 subtest

=cut

sub subtest {
    my ($self, $name, $code) = @_;

    ref $code eq 'CODE'
        or croak ("subtest(): second argument must be CODE!");

    my $subc = $self->subcontract( name => $name );
    &contract( $code, $subc );
};

=head2 done_testing

Finalize test engine and remove it from the stack.

=cut

sub done_testing {
    my $self = shift;

    $self->{done} and croak "done_testing() called twice";

    if ($self->{plan} and !$self->{skip_all} and $self->{plan} > 0 and $self->{plan} != $self->get_count) {
        $self->refute(
            sprintf( "made %d/%d tests", $self->get_count, $self->{plan} )
            , "plan failed!"
        )
    };

    $self->{done}++;
    $self->on_done;
    $self->_do_cleanup;

    return $self;
};

=head1 JOINING CONTRACTS

=head2 contract_is( $other_contract, "100101", "name..." )

Check that a given contract contains exactly the passed/failed tests
denoted by the bit string.

B<EXPERIMENTAL> The second argument's meaning MAY change or be extended
in the future.

See also sign() below.

=cut

sub contract_is {
    my ($self, $c, $condition, $name) = @_;

    # the happy case first
    my $not_ok = $c->get_failed;
    my @out = map { $not_ok->{$_} ? 0 : 1 } 1..$c->get_count;
    return $self->refute( '', $name )
        if $condition eq join "", @out;

    # analyse what went wrong - it did if we're here
    my @cond = split / *?/, $condition;
    my @fail;
    push @fail, "Contract signature: @out";
    push @fail, "Expected:           @cond";
    push @fail, sprintf "Tests executed: %d of %d", scalar @out, scalar @cond
        if @out != @cond;
    for (my $i = 0; $i<@out && $i<@cond; $i++) {
        next if $out[$i] eq $cond[$i];
        my $n = $i + 1;
        push @fail, "Unexpected " .($not_ok->{$n} ? "not ok $n" : "ok $n");
        if ($not_ok->{$n}) {
            push @fail, map { "DIAG # $_" } split /\n+/, $not_ok->{$n}[1]
        };
    };

    croak "Impossible: contract_is/sign broken. File a bug immediately!"
        if !@fail;
    return $self->refute( join "\n", @fail );
};


=head2 sign( expectation, comment)

Check that the contract is fulfilled to exactly the given extent,
AND record that test with the current GLOBAL contract engine
(likely NOT the calling object itself).

I<Somewhat twisted logic here...>

Expectations are currently supported in the only format:
a string of 0's and 1's.
More formats MAY follow in the future.

See contract_is() in L<Test::Contract::Basic>.

Usage is like this:

    use strict;
    use warnings;
    use Test::Contract;

    # ...
    contract {
        ok 1;
        ok 1;
        ok 0;
        ok 1;
    }->sign( "1101" );
    done_testing;

Returns self so that other methods MAY be chained.

B<EXPERIMENTAL> Name and meaning MAY change in the future.

=cut

sub sign {
    Test::Contract::Engine::Build::contract_engine()->contract_is( @_ );
    return shift;
};

sub _do_cleanup {
    my $self = shift;

    foreach my $sub ( @{ delete $self->{on_done} || [] } ) {
        eval { $sub->($self); 1 } or do {
            carp "[$$]: on_done callback failed: $@";
        };
    };

    Test::Contract::Engine::Build::contract_engine_cleanup();
        # TODO only if we're on the stack!
};

sub DESTROY {
    my $self = shift;
    $self->_do_cleanup;
};

=head1 GETTERS

=head2 get_done

Return truth if testing is finished.

=cut

sub get_done {
    my $self = shift;

    return $self->{done};
};

=head2 get_plan

Returns number of planned tests, if given, or number of tests done if done.

B<EXPERIMENTAL> Logic is not obvious.

=cut

sub get_plan {
    my $self = shift;

    return $self->{plan} || ($self->get_done && $self->get_count);
};

=head2 get_skipped

=cut

sub get_skipped {
    my $self = shift;
    return $self->{skip_all} || '';
};

=head2 get_count

Returns number of tests run so far

=cut

sub get_count {
    my $self = shift;
    return $self->{count} || 0;
};

=head2 get_passing

Returns truth if no tests failed so far.

=cut

sub get_passing {
    my $self = shift;
    return !$self->{fails} && !$self->{bail_out};
};

=head2 get_error_count

Returns number of tests that failed.

=cut

sub get_error_count {
    my $self = shift;
    return $self->{fails} || 0;
};

=head2 get_failed

Get failed tests as hash.

=cut

sub get_failed {
    my $self = shift;
    return $self->{failed};
};

=head2 get_tap

Get contract evaluation result as a multiline scalar.

May NOT be available in subclasses (dies in C<Test::Contract::Engine::TAP>).

=cut

sub get_tap {
    my ($self, $verbose) = @_;

    $verbose = 1 unless defined $verbose;
    $verbose++;

    my $dent = '    ' x $self->get_indent;
    return join "\n",
        (map { "$dent$_" } grep { !/^#{$verbose}/ } @{ $self->{log} })
        , '';
};

=head2 get_indent

Get the indentation level of the current contract.

Indentation increases with each subtest.

=cut

sub get_indent {
    my $self = shift;

    return $self->{indent} || 0;
};

=head2 get_mute

Tells if the engine was mutes.

=cut

sub get_mute {
    my $self = shift;
    return $self->{mute} && ( $self->{skip_all} || "muted" );
};

=head1 SETTERS

=head2 set_done_callback( sub { ... } );

Setup an action executed in destroy.

May be called multiple times, the actions will be executed in reverse order.

=cut

sub set_done_callback {
    my ($self, $code) = @_;

    ref $code eq 'CODE'
        or croak "set_done_callback: argument MUST be a sub";

    push @{ $self->{on_done} }, $code;
    return $self;
};

=head2 set_mute ( "reason" )

Don not output anything anymore. Also skip any upcoming tests.

This may be useful say after a fork.

=cut

sub set_mute {
    my ($self, $reason) = @_;

    $self->{mute}++;
    $self->skip_all( $reason || "Engine was muted" );
};

=head1 SUBCLASS METHODS

Redefine these methods to get a custom contract behavior.

=cut

=head2 on_pass( $name )

What to do when test passes.

=cut

sub on_pass {
    my ($self, $name) = @_;

    $self->_log( join " ", "ok", $self->get_count, $name ? ("-", $name) : () );
    return;
};

=head2 on_fail ( $name, $details )

What to do when test fails.

=cut

sub on_fail {
    my ($self, $name, $cond) = @_;

    $self->{failed}{ $self->get_count } = [ $name, $cond ];
    $self->_log( join " ", "not ok", $self->get_count, $name ? ("-", $name) : () );
    return;
};

=head2 diag( $message )

Add a serious warning message.

The interface MAY change in the future in favour of @list.

=cut

sub diag {
    my ($self, @mess) = @_;

    #
    croak "diag(): Testing finished"
        if $self->get_done;
    $self->_log( join " ", "#", $_ )
        for split /\n+/, join "",
            map { defined $_ && !ref $_ ? $_ : to_scalar($_); } @mess;
    return;
};

=head2 note( @message )

Add a side note warning message.

=cut

sub note {
    my ($self, @mess) = @_;

    $self->_log( join " ", "##", $_ )
        for split /\n+/, join "",
            map { defined $_ && !ref $_ ? $_ : to_scalar($_); } @mess;
    return;
};

=head2 on_done

What to do when done_testing is called.

=cut

sub on_done {
    my $self = shift;

    my $comment = $self->{skip_all} ? (' # SKIP '.$self->{skip_all} ) : '';
    $self->_log( "1.." .$self->get_count . $comment );
};

=head2 bail_out( $reason )

What to do when bail_out is called.

The interface MAY change in the future.

=cut

sub bail_out {
    my ($self, $mess) = @_;

    $mess ||= '';
    $self->_log( "Bail out! $mess" );
    $self->{skip_all} = "Bail out! $mess";
    $self->{bail_out} = $mess || "unknown reason";
    return;
};

sub _log {
    my ($self, $mess) = @_;

    $mess =~ s#\n+$##s;
    push @{ $self->{log} }, $mess;
};

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

This is alpha software, lots of bugs guaranteed.

Please report any bugs or feature requests to C<bug-test-refute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Contract>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Contract

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Contract>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Contract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Contract>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Contract/>

=back

=head1 ACKNOWLEDGEMENTS

Karl Popper (the philosopher) inspired me to invert assertion into refutation.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test::Contract
