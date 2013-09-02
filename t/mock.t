#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 19;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( get_attribute_value );
use Types::Standard   qw( Int );

# ----------------------
# creating a mock
my $mock = mock();
ok $mock, 'mock() creates a simple mock';

# ----------------------
# mocks pretend to be anything you want
ok $mock->isa('Bar'),  'mock can isa(anything)';
ok $mock->does('Baz'), 'mock can does(anything)';
ok $mock->DOES('Baz'), 'mock can DOES(anything)';

# ----------------------
# mocks accept any methods call on them
my $calls   = get_attribute_value($mock, 'calls');
my $coderef = $mock->can('foo');
ok $coderef,                    'mock can(anything)';
is ref($coderef), 'CODE',       ' and can() returns a coderef';
is $coderef->($mock, 1), undef, ' and can() coderef returns undef by default';
is $calls->[-1]->as_string, 'foo(1)', ' and method call is recorded';

is $mock->foo(bar => 1), undef,
    'mock accepts any method call, returning undef by default';
is $calls->[-1]->as_string, 'foo(bar: 1)', ' and method call is recorded';

# ----------------------
# type constraints
my $e = exception { $mock->foo(1, Int) };
like $e, qr/Int/,
    'mock does not accept method call with type constraint argument';
like $e, qr/mock\.t/, ' and message traces back to this script';

is $mock->foo(1, mock), undef, 'mock as method argument not isa(Type::Tiny)';

# ----------------------
# calling mock with a class
my $mock1 = mock('Foo');
ok $mock1,              'mock($class) creates a mock with a class';
is $mock1->ref, 'Foo',  ' and class is returned with ref method';
is ref($mock1), 'Foo',  ' and class is returned with ref function';

like exception { mock($mock1) },
    qr/^The argument for mock\(\) must be a string/,
    'the argument for mock() must be a string';

$mock->DESTROY;
isnt $calls->[-1]->as_string, 'DESTROY()', 'DESTROY() is not AUTOLOADed';
