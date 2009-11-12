#============================================================= -*-perl-*-
#
# t/parser/variables.t
#
# Parser tests for variables.
# Run with '-h' option for help with command line arguments.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib';
    
use Template::TT3::Test::Parser 
    debug  => 'Template::TT3::Tag',
    args   => \@ARGV,
    tests  => 4,
    import => 'test_parser';

test_parser(
    debug => $DEBUG,
);

__DATA__

-- test variable foo --
foo
-- expect -- 
<variable:foo>

-- test variable foo() --
foo()
-- expect -- 
<variable:
  <name:foo>
  <parens:>
>

-- test variable foo(10,20) --
foo(10,20)
-- expect -- 
<variable:
  <name:foo>
  <parens:
    <number:10>
    <number:20>
  >
>

-- test variable foo(10, bar(20)) --
foo(10,bar(20))
-- expect -- 
<variable:
  <name:foo>
  <parens:
    <number:10>
    <variable:
      <name:bar>
      <parens:
        <number:20>
      >
    >
  >
>

