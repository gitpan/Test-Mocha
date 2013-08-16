package Test::Mocha::Invocation;
{
  $Test::Mocha::Invocation::VERSION = '0.11';
}
# ABSTRACT: Represents a method call

use Moose;
use namespace::autoclean;

with 'Test::Mocha::Role::MethodCall';

__PACKAGE__->meta->make_immutable;
1;
