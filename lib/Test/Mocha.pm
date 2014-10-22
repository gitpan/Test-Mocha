use strict;
use warnings;
package Test::Mocha;
{
  $Test::Mocha::VERSION = '0.19';
}
# ABSTRACT: Test Spy/Stub Framework


use Carp     qw( croak );
use Exporter qw( import );
use Test::Mocha::Inspect;
use Test::Mocha::Mock;
use Test::Mocha::Stub;
use Test::Mocha::Types 'NumRange', Mock => { -as => 'MockType' };
use Test::Mocha::Util qw( get_attribute_value );
use Test::Mocha::Verify;
use Types::Standard qw( ArrayRef HashRef Num slurpy );

our @EXPORT = qw(
    mock
    stub
    verify
    inspect
    inspect_all
    clear
    SlurpyArray
    SlurpyHash
);


use constant {
    SlurpyArray => slurpy(ArrayRef),
    SlurpyHash  => slurpy(HashRef),
};


sub mock {
    return Test::Mocha::Mock->new if @_ == 0;

    my ($class) = @_;

    croak 'The argument for mock() must be a string'
        unless !ref $class;

    return Test::Mocha::Mock->new(class => $class);
}


sub stub {
    my ($mock) = @_;

    croak 'stub() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return Test::Mocha::Stub->new(mock => $mock);
}


sub verify {
    my $mock = shift;
    my $test_name;
    $test_name = pop if (@_ % 2 == 1);
    my %options = @_;

    # set default option if none given
    $options{times} = 1 if keys %options == 0;

    croak 'verify() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    croak 'You can set only one of these options: '
        . join ', ', map {"'$_'"} keys %options
        unless keys %options == 1;

    if (defined $options{times}) {
        croak "'times' option must be a number"
            unless Num->check( $options{times} );
    }
    elsif (defined $options{at_least}) {
        croak "'at_least' option must be a number"
            unless Num->check( $options{at_least} );
    }
    elsif (defined $options{at_most}) {
        croak "'at_most' option must be a number"
            unless Num->check( $options{at_most} );
    }
    elsif (defined $options{between}) {
        croak "'between' option must be an arrayref "
            . "with 2 numbers in ascending order"
            unless NumRange->check( $options{between} );
    }
    else {
        my ($option) = keys %options;
        croak "verify() was given an invalid option: '$option'";
    }

    # set test name if given
    $options{test_name} = $test_name if defined $test_name;

    return Test::Mocha::Verify->new(mock => $mock, %options);
}


sub inspect {
    my ($mock) = @_;

    croak 'inspect() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return Test::Mocha::Inspect->new(mock => $mock);
}


sub inspect_all {
    my ($mock) = @_;

    croak 'inspect_all() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return @{ $mock->{calls} };
}


sub clear {
    my ($mock) = @_;

    croak 'clear() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    my $calls = get_attribute_value($mock, 'calls');
    @$calls = ();

    return;
}

1;

__END__

=pod

=head1 NAME

Test::Mocha - Test Spy/Stub Framework

=head1 VERSION

version 0.19

=head1 SYNOPSIS

Test::Mocha is a test spy framework for testing code that has dependencies on
other objects.

    use Test::More tests => 2;
    use Test::Mocha;
    use Types::Standard qw( Int );

    # create the mock
    my $warehouse = mock;

    # stub method calls (with type constraint for matching argument)
    stub($warehouse)->has_inventory($item1, Int)->returns(1);

    # execute the code under test
    my $order = Order->new(item => $item1, quantity => 50);
    $order->fill($warehouse);

    # verify interactions with the dependent object
    ok( $order->is_filled, 'Order is filled' );
    verify( $warehouse, '... and inventory is removed' )->remove_inventory($item1, 50);

    # clear the invocation history
    clear($warehouse);

=head1 DESCRIPTION

We find all sorts of excuses to avoid writing tests for our code. Often it
seems too hard to isolate the code we want to test from the objects it is
dependent on. I'm too lazy and impatient to code my own mocks. Mocking
frameworks can help with this but they still take too long to set up the mock
objects. Enough setting up! I just want to get on with the actual testing.

Test::Mocha offers a simpler and more intuitive approach. Rather than setting
up the expected interactions beforehand, you ask questions about interactions
after the execution. The mocks can be created in almost no time. Yet they're
ready to be used out-of-the-box by pretending to be any type you want them to
be and accepting any method call on them.

Explicit stubbing is only required when the dependent object is expected to
return a specific response. And you can even use argument matchers to skip
having to enter the exact method arguments for the stub.

After executing the code under test, you can test that your code is interacting
correctly with its dependent objects. Selectively verify the method calls that
you are interested in only. As you verify behaviour, you focus on external
interfaces rather than on internal state.

=head1 FUNCTIONS

=head2 mock

    my $mock = mock;

C<mock()> creates a new mock object. It's that quick and simple!

The mock object is ready, as-is, to pretend to be anything you want it to be.
Calling C<isa()> or C<does()> on the object will always return true. This
is particularly handy when dependent objects are required to satisfy type
constraint checks with OO frameworks such as L<Moose>.

    ok( $mock->isa('AnyClass') );
    ok( $mock->does('AnyRole') );
    ok( $mock->DOES('AnyRole') );

It will also accept any method call on it. By default, method calls will
return C<undef> (in scalar context) or an empty list (in list context).

    ok( $mock->can('any_method') );
    is( $mock->any_method(@args), undef );

=head2 stub

    stub($mock)->method(@args)->returns|dies|executes($response)

By default, the mock object already acts as a stub that accepts any method
call and returns C<undef>. However, you can use C<stub()> to tell a method to
give an alternative response. You can specify 3 types of responses:

=over 4

=item C<returns(@values)>

Specifies that a stub should return 1 or more values.

    stub($mock)->method(@args)->returns(1, 2, 3);
    is_deeply( [ $mock->method(@args) ], [ 1, 2, 3 ] );

=item C<dies($message)>

Specifies that a stub should raise an exception.

    stub($mock)->method(@args)->dies('exception');
    ok( exception { $mock->method(@args) } );

=item C<executes($coderef)>

Specifies that a stub should execute the given callback. The arguments used
in the method call are passed on to the callback.

    my @returns = qw( first second third );

    stub($list)->get(Int)->executes(sub {
        my ($self, $i) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    });

    is( $list->get(0), 'first'  );
    is( $list->get(1), 'second' );
    is( $list->get(5), undef    );
    like( exception { $list->get(-1) }, qr/^index out of bounds/ ),

=back

A stub applies to the exact method and arguments specified (but see also
L</"ARGUMENT MATCHING"> for a shortcut around this).

    stub($list)->get(0)->returns('first');
    stub($list)->get(1)->returns('second');

    is( $list->get(0), 'first' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef );

Chain responses together to provide a consecutive series.

    stub($iterator)->next
        ->returns(1)->returns(2)->returns(3)->dies('exhuasted');

    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    ok( exception { $iterator->next } );

The last stubbed response will persist until it is overridden.

    stub($warehouse)->has_inventory($item, 10)->returns(1);
    ok( $warehouse->has_inventory($item, 10) ) for 1 .. 5;

    stub($warehouse)->has_inventory($item, 10)->returns(0);
    ok( !$warehouse->has_inventory($item, 10) ) for 1 .. 5;

=head2 verify

    verify($mock, [%option], [$test_name])->method(@args)

C<verify()> is used to test the interactions with the mock object. You can use
it to verify that the correct methods were called, with the correct set of
arguments, and the correct number of times. C<verify()> plays nicely with
L<Test::Simple> and Co - it will print the test result along with your other
tests and calls to C<verify()> are counted in the test plan.

    verify($warehouse)->remove($item, 50);
    # prints: ok 1 - remove("book", 50) was called 1 time(s)

An option may be specified to constrain the test.

=over 4

=item C<times>

Specifies the number of times the given method is expected to be called.
The default is 1 if no other option is specified.

    verify( $mock, times => 3 )->method(@args)
    # print: ok 1 - method(@args) was called 3 time(s)

=item C<at_least>

Specifies the minimum number of times the given method is expected to be
called.

    verify( $mock, at_least => 3 )->method(@args)
    # print: ok 1 - method(@args) was called at least 3 time(s)

=item C<at_most>

Specifies the maximum number of times the given method is expected to be
called.

    verify( $mock, at_most => 5 )->method(@args)
    # print: ok 1 - method(@args) was called at most 5 time(s)

=item C<between>

Specifies the minimum and maximum number of times the given method is
expected to be called.

    verify( $mock, between => [3, 5] )->method(@args)
    # prints: ok 1 - method(@args) was called between 3 and 5 time(s)

=back

An optional C<$test_name> may be specified to be printed instead of the
default.

    verify( $warehouse, 'inventory removed' )->remove_inventory($item, 50);
    # prints: ok 1 - inventory removed

    verify( $warehouse, times => 0, 'inventory not removed' )->remove_inventory($item, 50);
    # prints: ok 2 - inventory not removed

=head2 inspect

    @method_calls = inspect($mock)->method(@args)

C<inspect()> returns a list of method calls matching the given method call
specification. It can be useful for debugging failed C<verify()> calls. Or use
it in place of a complex C<verify()> call to break it down into smaller tests.

Each method call object has a C<name> and an C<args> property, and it
is C<string> overloaded.

    my ($method_calls) = inspect($warehouse)->remove_inventory(Str, Int);

    is( $method_call->name, 'remove_inventory',       'method name' );
    is_deeply( [$method_call->args], ['book', 50],    'method args array' );
    is( $method_call, 'remove_inventory("book", 50)', 'method as string' );

=head2 inspect_all

    @all_method_calls = inspect_all($mock)

C<inspect_all()> returns a list containing all methods called on the mock
object. This is mainly used for debugging.

=head2 clear

    clear($mock)

Clears the method call history of the mock for it to be reused in another test.
Note that this does not affect the stubbed methods.

=for Pod::Coverage SlurpyArray SlurpyHash

=head1 ARGUMENT MATCHING

Argument matchers may be used in place of specifying exact method arguments.
They allow you to be more general and will save you much time in your
method specifications to stubs and verifications. Argument matchers may be used
with C<stub()>, C<verify()> and C<inspect>.

=head2 Pre-defined types

You may use any of the ready-made types in L<Types::Standard>. (Alternatively,
Moose types like those in L<MooseX::Types::Moose> and
L<MooseX::Types::Structured> will also work.)

    use Types::Standard qw( Any );

    my $mock = mock;
    stub($mock)->foo(Any)->returns('ok');

    print $mock->foo(1);        # prints: ok
    print $mock->foo('string'); # prints: ok

    verify($mock, times => 2)->foo(Defined);
    # prints: ok 1 - foo(Defined) was called 2 time(s)

You may use the normal features of the types: parameterized and structured
types, and type unions, intersections and negations (but there's no need to
use coercions).

    use Types::Standard qw( Any ArrayRef HashRef Int StrMatch );

    my $list = mock;
    $list->set(1, [1,2]);
    $list->set(0, 'foobar');

    # parameterized type
    # prints: ok 1 - set(Int, StrMatch[(?^:^foo)]) was called 1 time(s)
    verify($list)->set( Int, StrMatch[qr/^foo/] );

=head2 Self-defined types

You may also use your own types, defined using L<Type::Utils>.

    use Type::Utils -all;

    # naming the type means it will be printed nicely in the verify() output
    my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };

    # prints: ok 2 - set(PositiveInt, Any) was called 1 time(s)
    verify($list)->set( $positive_int, Any );

=head2 Argument slurping

C<SlurpyArray> and C<SlurpyHash> are special argument matchers exported by
Test::Mocha that you can use when you don't care what arguments are used.
They will just slurp up the remaining arguments as though they match.

    verify($list)->set( SlurpyArray );
    verify($list)->set( Int, SlurpyHash );

Because they consume the remaining arguments, you can't use further argument
validators after them. But you can, of course, use them before. Note also that
they will match empty argument lists.

=head1 TO DO

=over 4

=item *

Enhanced verifications

=item *

Module functions and class methods

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-mocha at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mocha>. You will be automatically notified of any
progress on the request by the system.

=head1 AUTHOR

Steven Lee <stevenwh.lee@gmail.com>

=head1 ACKNOWLEDGEMENTS

This module is a fork from L<Test::Magpie> originally written by Oliver
Charles (CYCLES).

It is inspired by the popular L<Mockito|http://code.google.com/p/mockito/>
for Java and Python by Szczepan Faber.

=head1 SEE ALSO

L<Test::MockObject>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Lee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
