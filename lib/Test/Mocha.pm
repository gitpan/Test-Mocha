use strict;
use warnings;
package Test::Mocha;
{
  $Test::Mocha::VERSION = '0.11';
}
# ABSTRACT: Test Spy/Stub Framework


use aliased 'Test::Mocha::Inspect';
use aliased 'Test::Mocha::Mock';
use aliased 'Test::Mocha::Stubber';
use aliased 'Test::Mocha::Verify';

use Carp qw( croak );
use Exporter qw( import );
use Scalar::Util qw( looks_like_number );
use Test::Mocha::Types 'NumRange', Mock => { -as => 'MockType' };

our @EXPORT = qw(
    mock
    stub
    verify
);
our @EXPORT_OK = qw(
    inspect
);


sub mock {
    return Mock->new if @_ == 0;

    my ($class) = @_;

    croak 'The argument for mock() must be a string'
        unless !ref $class;

    return Mock->new(class => $class);
}


sub stub {
    my ($mock) = @_;

    croak 'stub() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return Stubber->new(mock => $mock);
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
            unless looks_like_number $options{times};
    }
    elsif (defined $options{at_least}) {
        croak "'at_least' option must be a number"
            unless looks_like_number $options{at_least};
    }
    elsif (defined $options{at_most}) {
        croak "'at_most' option must be a number"
            unless looks_like_number $options{at_most};
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

    return Verify->new(mock => $mock, %options);
}


sub inspect {
    my ($mock) = @_;

    croak 'inspect() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return Inspect->new(mock => $mock);
}

1;

__END__

=pod

=head1 NAME

Test::Mocha - Test Spy/Stub Framework

=head1 VERSION

version 0.11

=head1 SYNOPSIS

Test::Mocha is a test spy framework for testing code that has dependencies on
other objects.

    use Test::More tests => 2;
    use Test::Mocha;

    # set up the mock, and stub method calls
    my $warehouse = mock;
    stub($warehouse)->has_inventory($item1, 50)->returns(1);

    # execute the code under test
    my $order = Order->new(item => $item1, quantity => 50);
    $order->fill($warehouse);

    # verify interactions with the dependent object
    ok( $order->is_filled, 'Order is filled' );
    verify( $warehouse, '... and inventory is removed' )
        ->remove_inventory($item1, 50);

=head1 DESCRIPTION

We find all sorts of excuses to avoid writing tests for our code. Often it
seems too hard to isolate the code we want to test from the objects it is
dependent on. Mocking frameworks are available to help us with this. But it
still takes too long to set up the mock objects before you can get on with
testing the actual code in question.

Test::Mocha offers a simpler and more intuitive approach. Rather than setting
up the expected interactions beforehand, you ask questions about interactions
after the execution. The mocks can be created in almost no time. Yet they are
ready to be used out-of-the-box by pretending to be any type you want them to
be and accepting any method call on them. Explicit stubbing is only required
when the dependent object is expected to return a response. After executing
the code under test, you can selectively verify the interactions that you are
interested in. As you verify behaviour, you focus on external interfaces
rather than on internal state.

=head1 FUNCTIONS

=head2 mock

C<mock()> creates a new mock object.

    my $mock = mock;

By default, the mock object pretends to be anything you want it to be. Calling
C<isa()> or C<does()> on the object will always return true.

    ok( $mock->isa('AnyClass') );
    ok( $mock->does('AnyRole') );
    ok( $mock->DOES('AnyRole') );

It will also accept any method call on it. By default, any method call will
return C<undef> (in scalar context) or an empty list (in list context).

    ok( $mock->can('any_method') );
    is( $mock->any_method(@args), undef );

=head2 stub

C<stub()> is used when you need a method to respond with something other than
returning C<undef>. Use it to tell a method to return some value(s) or to
raise an exception.

    stub($mock)->method_that_returns(@args)->returns(1, 2, 3);
    stub($mock)->method_that_dies(@args)->dies('exception');

    is_deeply( [ $mock->method_that_returns(@args) ], [ 1, 2, 3 ] );
    ok( exception { $mock->method_that_dies(@args) } );

The stub applies to the exact method and arguments specified.

    stub($list)->get(0)->returns('first');
    stub($list)->get(1)->returns('second');

    is( $list->get(0), 'first' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef );

A stubbed response will persist until it is overridden.

    stub($warehouse)->has_inventory($item, 10)->returns(1);
    ok( $warehouse->has_inventory($item, 10) ) for 1 .. 5;

    stub($warehouse)->has_inventory($item, 10)->returns(0);
    ok( !$warehouse->has_inventory($item, 10) ) for 1 .. 5;

You may chain responses together to provide a series of responses.

    stub($iterator)->next
        ->returns(1)->returns(2)->returns(3)->dies('exhuasted');
    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    ok( exception { $iterator->next } );

=head2 verify

    verify($mock, [%option], [$test_name])->method(@args)

C<verify()> is used to test the interactions with the mock object. C<verify()>
plays nicely with L<Test::Simple> and Co - it will print the test result along
with your other tests and calls to C<verify()> are counted in the test plan.

    verify($warehouse)->remove($item, 50);
    # prints: ok 1 - remove("coffee", 50) was called 1 time(s)

An option may be specified to constrain the test.

    verify( $mock, times => 3 )->method(@args)
    verify( $mock, at_least => 3 )->method(@args)
    verify( $mock, at_most => 5 )->method(@args)
    verify( $mock, between => [3, 5] )->method(@args)

=over 4

=item times

Specifies the number of times the given method is expected to be called. The
default is 1 if no other option is specified.

=item at_least

Specifies the minimum number of times the given method is expected to be
called.

=item at_most

Specifies the maximum number of times the given method is expected to be
called.

=item between

Specifies the minimum and maximum number of times the given method is expected
to be called.

=back

An optional C<$test_name> may be specified to be printed instead of the
default.

    verify( $warehouse, 'inventory removed')->remove_inventory($item, 50);
    # prints: ok 1 - inventory removed

    verify( $warehouse, times => 0, 'inventory not removed')
        ->remove_inventory($item, 50);
    # prints: ok 2 - inventory not removed

=for Pod::Coverage inspect

=head1 TO DO

=over 4

=item *

Rethink Matchers

=item *

Ordered verifications

=item *

Function to clear interaction history

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

It is inspired by L<Mockito|http://code.google.com/p/mockito/> for Java and
Python by Szczepan Faber.

=head1 SEE ALSO

L<Test::MockObject>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Lee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
