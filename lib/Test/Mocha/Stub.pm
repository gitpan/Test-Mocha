package Test::Mocha::Stub;
{
  $Test::Mocha::Stub::VERSION = '0.20';
}
# ABSTRACT: Mock wrapper to create method stubs

use strict;
use warnings;

use Carp qw( croak );
use Test::Mocha::MethodStub;
use Test::Mocha::Types  qw( Mock Slurpy );
use Test::Mocha::Util   qw( extract_method_name getattr );
use Types::Standard     qw( ArrayRef HashRef );

our $AUTOLOAD;

sub new {
    # uncoverable pod
    my ($class, %args) = @_;
    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    return bless \%args, $class;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method_name = extract_method_name($AUTOLOAD);

    my $i = 0;
    my $seen_slurpy;
    foreach (@args) {
        if (Slurpy->check($_)) {
            $seen_slurpy = 1;
            last;
        }
        $i++;
    }
    croak 'No arguments allowed after a slurpy type constraint'
        if $i < $#args;

    if ($seen_slurpy) {
        my $slurpy = $args[$i]->{slurpy};
        croak 'Slurpy argument must be a type of ArrayRef or HashRef'
            unless $slurpy->is_a_type_of(ArrayRef)
                || $slurpy->is_a_type_of(HashRef);
    }

    my $stub = Test::Mocha::MethodStub->new(
        name => $method_name,
        args => \@args,
    );

    my $mock  = getattr($self, 'mock');
    my $stubs = getattr($mock, 'stubs');

    # add new stub to front of queue so that it takes precedence
    # over existing stubs that would satisfy the same invocations
    unshift @{ $stubs->{$method_name} }, $stub;

    return $stub;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

1;
