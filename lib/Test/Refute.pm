package Test::Refute;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.0116;

=head1 NAME

Test::Refute - a lightweight unit-testing and assertion tool.

=head1 SYNOPSIS

The following is a prove-compatible test script. (See L<Test::More>).

    use strict;
    use warnings;
    use Test::Refute;

    use_ok( "My::Module" );

    is (My::Module->answer, 42, "Life, universe, and everything");

    done_testing; # required

However, it can also work inside an application:

    use Test::Refute qw(contract);

    my $contract = contract {
        is ($user_input->{foo}, $bar, "Input as expected" );
        like ($user_input->{baz}, qr/f?o?r?m?a?t?/, "Format good" );
    };
    if (!$contract->is_valid) {
        ...
    };

Or using the OO interface, if you prefer:

    use Test::Refute::Contract;
    my $contract = Test::Refute::Contract->new;
    $contract->like( $something, $something_else );
    $contract->done_testing; # this may be omitted
    if (!$contract->is_valid) {
        ...
    };

There's also the central point of this module - the inverted assertion:

    $contract->refute ( $what_exactly_went_wrong, $human_explanation);
    # silent if arg1 is false, complains otherwise

In theory, there should also be an assertion wrapper that dies on failed
conditions and optimizes itself out if needed. That's not done yet.

Extending the test suite goes as follows:

    package My::Package;
    use Test::Refute::Build;
    use parent qw(Exporter);

    build_refute is_everything => sub {
        return if $_[0] == 42;
        return "$_[0] is not answer to life, universe, abd everything";
    }, export => 1, args => 1;

    1;

The function provided to builder must return a false value if everything is ok,
or some details (but generally any true value) if not.

This call will create a prototyped function is_everything(...) in the calling
package, with C<args> positional parameters and an optional human-readable
message. (Think "ok 1", "ok 1 'test passed'").

It will also create a corresponding is_everything method in
L<Test::Refute::Contract> package so that OO interface described above
is always on par with functional one.
This is the main reason to need a builder at all.
Suggestions how to reduce it even more are welcome.
See L<Test::Refute::Build>.

=head1 EXPORT

All functions in this module are exported by default.

=head1 FUNCTIONS

=cut

use Carp;

use Test::Refute::Build;
use Test::Refute::Basic;
use Test::Refute::Contract qw(contract);
use Test::Refute::TAP;
use Test::Refute::Deep;

use parent qw(Exporter);
my @wrapper = qw(done_testing note diag bail_out subtest);
my @own = qw(BAIL_OUT explain plan skip $TODO pass fail);
my @reexport = qw(contract is_deeply plan);
our @EXPORT = (@own, @wrapper, @reexport, @Test::Refute::Basic::EXPORT);
my $main_engine;
my $no_plan_seen;
our $TODO; # unimplemented - use contract instead!

# FIXME Have to make ugly hacks for Test::More compatibility

sub import {
    my ($self, $t, @rest) = @_;

    # Set up global testing engine FIRST, but ONLY once and ONLY if use'd
    $main_engine ||= Test::Refute::TAP->new;
    $main_engine->start_testing;

    if ($t and $t eq 'tests') {
        plan( tests => shift @rest );
        @_ = ($self, @rest);
    }
    elsif( $t and $t eq 'no_plan') {
        carp "DEPRECATED. put a done_testing(); at the end of the script and remove 'no_plan'";
        @_ = ($self, @rest);
        $no_plan_seen++;
    };

    goto &Exporter::import; ## no critic
};

=head1 TESTS

See L<Test::Refute::Basic> for checks allowed by default.

=head2 plan tests => nnn

Declare test plan (see Test::More).

done_testing() is still required, and plan will still be output at the end.

Generates 1 extra failed test if plan was declared and not fulfilled.

=head2 plan skip_all => $reason

Skip all tests.

=cut

sub plan($$) { ## no critic
    my ($todo, $arg) = @_;

    if ($todo eq 'tests') {
        $todo = 'plan';
    }
    elsif( $todo ne 'skip_all' ) {
        croak( "plan(): only (tests => nnn) or (skip_all => reason) args supported" );
    };

    refute_engine->$todo( $arg );
    if (refute_engine eq $main_engine and $todo eq 'skip_all') {
        exit 0; # Yuuuurgh - Test::More compat :(
    };
};

=head2 diag( $text )

Record a human-readable diagnostic message.

=head2 note( $text )

Record a human-readable sidenote.

=head2 explain( $unknown_scalar )

Convert scalar to human-readable form. This is really a stub for now.

=cut

sub explain ($) { ## no critic
    return to_scalar(shift, 3);
};

=head2 subtest "name" => CODE;

Create an indented sub-test.

=head2 pass $message

=head2 fail $message

Would log an (un)successful test.

B<DEPRECATED>. If you want to build custom test, use refute() primitive instead.
This is mainly here for compatibility, and issues a warning.

=cut

sub pass($) { ## no critic
    carp "pass(): DEPRECATED. Build your own tests using the refute() primitive.";
    ok (1, @_);
};

sub fail($) { ## no critic
    carp "fail(): DEPRECATED. Build your own tests using the refute() primitive.";
    ok (0, @_);
};

=head2 done_testing;

Finish testing, no more tests in the current batch
can be executed after this call.

=head2 bail_out( $text )

=head2 BAIL_OUT( $text )

Stop testing here, interrupting all further testing.

=cut

=head2 skip( ... )

Here for compatibility with Test::More.

It only warns when called, doesn't skip anything.

=cut

sub skip(@) { ## no critic
    carp "skip(): UNIMPLEMENTED. Use simple if() instead.";
};

END {
    if ($main_engine and $main_engine->test_number) {
        croak "done_testing was not seen"
            unless $main_engine->get_plan or $no_plan_seen;

        $main_engine->done_testing
            unless $main_engine->is_done;

        my $ret = $main_engine->error_count;
        $ret = 100 if $ret > 100;
        $? = $ret;
    }
    elsif ($main_engine and $main_engine->is_skipped) {
        $main_engine->done_testing
            unless $main_engine->is_done;
    };
};

# Setup wrapper functions - really proxy to the current contract
foreach (@wrapper) {
    my $name = $_;

    my $code = sub (@) { ## no critic
        refute_engine->$name(@_);
    };

    no strict 'refs'; ## no critic
    *$name = $code;
};

{
    no warnings 'once'; ## no critic
    *BAIL_OUT = \&bail_out; # alias
};

=head2 contract { CODE; };

=head2 contract { CODE; } $refute_object;

Run an enclosed set of tests, recording the results for future analysis.
Returns a contract object.
See GETTERS in L<Test::Refute::Contract> for reference.

=cut

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

This is alpha software, lots of bugs guaranteed.

Please report any bugs or feature requests to C<bug-test-refute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Refute>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Refute

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Refute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Refute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Refute>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Refute/>

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

1; # End of Test::Refute
