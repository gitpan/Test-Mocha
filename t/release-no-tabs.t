
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.02

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Mocha.pm',
    'lib/Test/Mocha/Inspect.pm',
    'lib/Test/Mocha/Method.pm',
    'lib/Test/Mocha/MethodCall.pm',
    'lib/Test/Mocha/MethodStub.pm',
    'lib/Test/Mocha/Mock.pm',
    'lib/Test/Mocha/PartialDump.pm',
    'lib/Test/Mocha/Stub.pm',
    'lib/Test/Mocha/Types.pm',
    'lib/Test/Mocha/Util.pm',
    'lib/Test/Mocha/Verify.pm'
);

notabs_ok($_) foreach @files;
done_testing;
