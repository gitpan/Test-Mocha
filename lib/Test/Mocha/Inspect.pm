package Test::Mocha::Inspect;
{
  $Test::Mocha::Inspect::VERSION = '0.12';
}
# ABSTRACT: Inspect method calls on mock objects

use Moose;
use namespace::autoclean;

use aliased 'Test::Mocha::Invocation';

use List::Util qw( first );
use Test::Mocha::Util qw( extract_method_name get_attribute_value );

with 'Test::Mocha::Role::HasMock';

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my $inspect = Invocation->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $calls = get_attribute_value($mock, 'calls');

    return first { $inspect->satisfied_by($_) } @$calls;
}

__PACKAGE__->meta->make_immutable;
1;
