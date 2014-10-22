package Test::Mocha::StubbedCall;
{
  $Test::Mocha::StubbedCall::VERSION = '0.14';
}
# ABSTRACT: The declaration of a stubbed method

# Represents a stub method - a method that may have some sort of action when
# called. Stub methods are created by invoking the method name (with a set of
# possible argument matchers/arguments) on the object returned by C<when> in
# L<Test::Mocha>.
#
# Stub methods have a stack of executions. Every time the stub method is called
# (matching arguments), the next execution is taken from the front of the queue
# and called. As stubs are matched via arguments, you may have multiple stubs
# for the same method name.

use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( blessed );

our @ISA = qw( Test::Mocha::MethodCall );

# croak() messages should not trace back to Mocha modules
# to facilitate debugging of user test scripts
our @CARP_NOT = qw( Test::Mocha::Mock );

sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{executions} = [];

    return $self;
}

# returns(@return_values)
#
# Pushes a stub method that will return the given values to the end of the
# execution queue.

sub returns {
    # uncoverable pod
    my ($self, @return_values) = @_;

    push @{ $self->{executions} }, sub {
        return wantarray || @return_values > 1
            ? @return_values
            : $return_values[0];
    };
    return $self;
}

# dies($exception)
#
# Pushes a stub method that will throw C<$exception> when called to the end of
# the execution queue.

sub dies {
    # uncoverable pod
    my ($self, $exception) = @_;

    push @{ $self->{executions} }, sub {
        $exception->throw
            if blessed($exception) && $exception->can('throw');

        croak $exception;
    };
    return $self;
}

# Executes the next execution

sub execute {
    # uncoverable pod
    my ($self) = @_;
    my $executions = $self->{executions};

    # return undef by default
    return if @$executions == 0;

    # use the execution at the front of the queue and
    # shift it off the queue - unless it is the last one
    my $execution = @$executions > 1
        ? shift(@$executions)
        : $executions->[0];

    return $execution->();
}

1;
