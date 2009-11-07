#============================================================= -*-perl-*-
#
# t/parser/boolops.t
#
# Parser tests for boolean operators.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test::Parser 
    tests  => 12,
    debug  => 'Template::TT3::Parser Template::TT3::Test::Parser',
    args   => \@ARGV,
    import => 'test_parser';

test_parser();

__DATA__

#-----------------------------------------------------------------------
# prefix !/not operators
#-----------------------------------------------------------------------

-- test prefix: ! --
! 10
-- expect --
<prefix:<op:!><number:10>>

-- test prefix: not --
not 10
-- expect --
<prefix:<op:not><number:10>>

-- test prefix precedence: ! --
! 10 + 20
-- expect --
<binary:<op:+><prefix:<op:!><number:10>><number:20>>

-- test prefix precedence: not --
not 10 + 20
-- expect --
<prefix:<op:not><binary:<op:+><number:10><number:20>>>

-- test infix: && --
10 && 20
-- expect --
<binary:<op:&&><number:10><number:20>>

-- test infix: and --
10 and 20
-- expect --
<binary:<op:and><number:10><number:20>>

-- test infix: || --
10 || 20
-- expect --
<binary:<op:||><number:10><number:20>>

-- test infix: or --
10 or 20
-- expect --
<binary:<op:or><number:10><number:20>>

-- test infix precedence: && --
10 + 20 && 30 + 40 
-- expect --
-- collapse --
<binary:
  <op:&&>
  <binary:
    <op:+>
    <number:10>
    <number:20>
  >
  <binary:
    <op:+>
    <number:30>
    <number:40>
  >
>

-- test infix precedence: and --
10 + 20 and 30 + 40 
-- expect --
-- collapse --
<binary:
  <op:and>
  <binary:
    <op:+>
    <number:10>
    <number:20>
  >
  <binary:
    <op:+>
    <number:30>
    <number:40>
  >
>

-- test infix precedence: || --
10 + 20 || 30 + 40 
-- expect --
-- collapse --
<binary:
  <op:||>
  <binary:
    <op:+>
    <number:10>
    <number:20>
  >
  <binary:
    <op:+>
    <number:30>
    <number:40>
  >
>

-- test infix precedence: or --
10 + 20 or 30 + 40 
-- expect --
-- collapse --
<binary:
  <op:or>
  <binary:
    <op:+>
    <number:10>
    <number:20>
  >
  <binary:
    <op:+>
    <number:30>
    <number:40>
  >
>



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

