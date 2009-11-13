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
    tests  => 11,
    import => 'test_parser';

test_parser(
    debug => $DEBUG,
);

__DATA__


#-----------------------------------------------------------------------
# simple variables
#-----------------------------------------------------------------------

-- test variable foo --
foo
-- expect -- 
<variable:foo>

-- test variable foo() --
foo()
-- expect -- 
<apply:
  <variable:foo>
  <args:>
>

-- test variable foo(10,20) --
foo(10,20)
-- expect -- 
<apply:
  <variable:foo>
  <args:
    <number:10>
    <number:20>
  >
>

-- test variable foo(10, bar(20)) --
foo(10,bar(20))
-- expect -- 
<apply:
  <variable:foo>
  <args:
    <number:10>
    <apply:
      <variable:bar>
      <args:
        <number:20>
      >
    >
  >
>

#-----------------------------------------------------------------------
# sigils
#-----------------------------------------------------------------------

-- test variable $foo --
$foo
-- expect --
<$:
  <variable:foo>
>

-- test variable $foo() --
$foo()
-- expect --
<$:
  <apply:
    <variable:foo>
    <args:>
  >
>

-- test variable $foo(10,20) --
$foo(10,20)
-- expect --
<$:
  <apply:
    <variable:foo>
    <args:
      <number:10>
      <number:20>
    >
  >
>


-- test variable @foo --
@foo
-- expect --
<@:
  <variable:foo>
>

-- test variable @foo() --
@foo()
-- expect --
<@:
  <apply:
    <variable:foo>
    <args:>
  >
>

-- test variable @foo(10,20) --
@foo(10,20)
-- expect --
<@:
  <apply:
    <variable:foo>
    <args:
      <number:10>
      <number:20>
    >
  >
>


#-----------------------------------------------------------------------
# dotop args
#-----------------------------------------------------------------------

-- test list.join(', ') --
list.join(', ')
-- expect --
<dot:
  <variable:list>
  <literal:join>
  <args:
    <text:, >
  >
>
