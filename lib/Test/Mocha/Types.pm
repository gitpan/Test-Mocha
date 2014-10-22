package Test::Mocha::Types;
{
  $Test::Mocha::Types::VERSION = '0.16';
}
# ABSTRACT: Internal type constraints

use Type::Library
    -base,
    -declare => qw(
        Matcher
        Mock
        NumRange
        Slurpy
    );

use Type::Utils -all;
use Types::Standard qw( Dict InstanceOf Num Tuple );

union Matcher, [
    class_type( { class => 'Type::Tiny' } ),
    class_type( { class => 'Moose::Meta::TypeConstraint' } ),
];

class_type Mock, { class => 'Test::Mocha::Mock' };

declare NumRange, as Tuple[Num, Num], where { $_->[0] < $_->[1] };

# this hash structure is created by Types::Standard::slurpy()
declare Slurpy, as Dict[ slurpy => InstanceOf['Type::Tiny'] ];

1;
