#============================================================= -*-perl-*-
#
# t/parser/brackets.t
#
# Parser tests for [bracketed expressions]
#
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
    
use Template::TT3::Test
    tests  => 3,
    debug  => 'Template::TT3::Tag Template::TT3::Element',
    args   => \@ARGV,
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


-- test curly braces --
{ a=10, b=20 }
-- expect -- 
<hash:
  <binary:<op:=><variable:a><number:10>>
  <binary:<op:=><variable:b><number:20>>
>

__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:



