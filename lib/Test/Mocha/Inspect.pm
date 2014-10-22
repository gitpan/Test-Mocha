package Test::Mocha::Inspect;
{
  $Test::Mocha::Inspect::VERSION = '0.20';
}
# ABSTRACT: Mock wrapper to inspect method calls

use strict;
use warnings;

use Test::Mocha::Method;
use Test::Mocha::Types qw( Mock );
use Test::Mocha::Util  qw( extract_method_name getattr );

our $AUTOLOAD;

sub new {
    # uncoverable pod
    my ($class, %args) = @_;
    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    return bless \%args, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $inspect = Test::Mocha::Method->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = getattr($self, 'mock');
    my $calls = getattr($mock, 'calls');

    return grep { $inspect->satisfied_by($_) } @$calls;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

1;
