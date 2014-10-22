package Test::Mocha::Mock;
{
  $Test::Mocha::Mock::VERSION = '0.50';
}
# ABSTRACT: Mock objects

use strict;
use warnings;

use Carp 1.22           qw( croak );
use Test::Mocha::MethodCall;
use Test::Mocha::MethodStub;
use Test::Mocha::Types  qw( Matcher Slurpy );
use Test::Mocha::Util   qw( extract_method_name find_caller find_stub
                            getattr has_caller_package );
use Types::Standard     qw( ArrayRef HashRef Str );
use UNIVERSAL::ref;

our $AUTOLOAD;
our $num_method_calls = 0;
our $last_method_call;
our $last_execution;

# Classes for which mock isa() should return false
my %Isnota = (
    'Type::Tiny' => undef,
    'Moose::Meta::TypeConstraint' => undef,
);

# can() should always return a reference to the C<AUTOLOAD()> method
my $CAN = Test::Mocha::MethodStub->new(
    name => 'can',
    args => [ Str ],
)->executes(sub {
    my ($self, $method_name) = @_;
    return sub {
        $AUTOLOAD = $method_name;
        goto &AUTOLOAD;
    };
});

# DOES() should always return true
my $DOES_UC = Test::Mocha::MethodStub->new(
    name => 'DOES',
    args => [ Str ],
)->returns(1);

# does() should always return true
my $DOES_LC = Test::Mocha::MethodStub->new(
    name => 'does',
    args => [ Str ],
)->returns(1);

# isa() should always returns true
my $ISA = Test::Mocha::MethodStub->new(
    name => 'isa',
    args => [ Str ] ,
)->returns(1);


sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = bless {@_}, $class;

    # ArrayRef[ MethodCall ]
    $self->{calls} = [];

    # $method_name => ArrayRef[ MethodStub ]
    $self->{stubs} = {
        can  => [ $CAN     ],
        DOES => [ $DOES_UC ],
        does => [ $DOES_LC ],
        isa  => [ $ISA     ],
    };

    return $self;
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $method_name = extract_method_name($AUTOLOAD);

    undef $last_method_call;
    undef $last_execution;

    # check slurpy type constraint
    {
        my $i = 0;
        my $seen_slurpy;
        foreach ( @args ) {
            if ( Slurpy->check($_) ) {
                $seen_slurpy = 1;
                last;
            }
            $i++;
        }
        croak 'No arguments allowed after a slurpy type constraint'
            if $i < $#args;

        if ( $seen_slurpy ) {
            my $slurpy = $args[$i]->{slurpy};
            croak 'Slurpy argument must be a type of ArrayRef or HashRef'
                unless $slurpy->is_a_type_of(ArrayRef)
                    || $slurpy->is_a_type_of(HashRef);
        }
    }

    $num_method_calls++;

    my $calls = getattr( $self, 'calls' );
    my $stubs = getattr( $self, 'stubs' );

    # record the method call for verification
    $last_method_call = Test::Mocha::MethodCall->new(
        invocant => $self,
        name     => $method_name,
        args     => \@args,
        caller   => [ find_caller ],
    );
    push @$calls, $last_method_call;

    # find a stub to return a response
    my $stub = find_stub( $self, $last_method_call );
    if ( defined $stub ) {
        # save reference to stub execution so it can be restored
        my $executions  = getattr( $stub, 'executions' );
        $last_execution = $executions->[0] if @$executions > 1;

        return $stub->do_next_execution( $self, @args );
    }
    return;
}

# Let AUTOLOAD() handle the UNIVERSAL methods

sub isa {
    # uncoverable pod
    my ( $self, $class ) = @_;

    # Handle internal calls from UNIVERSAL::ref::_hook()
    # when ref($mock) is called
    return 1 if $class eq __PACKAGE__;

    # In order to allow mock methods to be called with other mocks as
    # arguments, mocks cannot isa() type constraints, which are not allowed
    # as arguments.
    return if exists $Isnota{ $class };

    $AUTOLOAD = 'isa';
    goto &AUTOLOAD;
}

sub DOES {
    # uncoverable pod
    my ( $self, $role ) = @_;

    # Handle internal calls from UNIVERSAL::ref::_hook()
    # when ref($mock) is called
    return 1 if $role eq __PACKAGE__;

    return if !ref($self);

    $AUTOLOAD = 'DOES';
    goto &AUTOLOAD;
}

sub can {
    # uncoverable pod
    my ( $self, $method_name ) = @_;

    # Handle can('CARP_TRACE') for internal croak()'s (Carp v1.32+)
    return if $method_name eq 'CARP_TRACE';

    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

sub ref {
    # uncoverable pod
    $AUTOLOAD = 'ref';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

1;
