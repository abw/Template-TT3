#============================================================= -*-perl-*-
#
# t/parser/brackets.t
#
# Parser tests for [bracketed expressions]
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
    tests  => 2,
    import => 'test_parser';

test_parser(
    debug => $DEBUG,
);

__DATA__

#------------------------------------------------------------------------
# numbers
#------------------------------------------------------------------------

-- test brackets --
[1, 2, 3]
-- expect -- 
<list:
  <number:1>
  <number:2>
  <number:3>
>

-- test nested brackets --
[1, 2, [3 4]]
-- expect -- 
<list:
  <number:1>
  <number:2>
  <list:
    <number:3>
    <number:4>
  >
>

