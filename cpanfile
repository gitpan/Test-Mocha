requires "Carp" => "1.22";
requires "Exporter" => "0";
requires "Scalar::Util" => "0";
requires "Test::Builder" => "0";
requires "Try::Tiny" => "0";
requires "Type::Library" => "0";
requires "Type::Utils" => "0";
requires "Types::Standard" => "0.008";
requires "UNIVERSAL::ref" => "0";
requires "constant" => "0";
requires "experimental" => "0";
requires "overload" => "0";
requires "perl" => "5.010001";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Test::Builder::Tester" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Requires" => "0";
  requires "version" => "0.77";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Moose::Util::TypeConstraints" => "0";
  requires "MooseX::Types::Moose" => "0";
  requires "MooseX::Types::Structured" => "0";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
};
