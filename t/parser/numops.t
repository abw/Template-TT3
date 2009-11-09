#============================================================= -*-perl-*-
#
# t/parser/numbers.t
#
# Parser tests for numbers and numerical operators.  
# Run with '-h' option for help with command line arguments.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test::Parser 
    debug  => 'Template::TT3::Parser Template::TT3::Test::Parser',
    args   => \@ARGV,
    tests  => 46,
    import => 'test_parser';

test_parser(
#    parse_method => 'parse_term',
#    view_method  => 'sexpr',
    debug        => $DEBUG,
);

__DATA__

#------------------------------------------------------------------------
# numbers
#------------------------------------------------------------------------

-- test integers --
0
1
123
123445
-- expect -- 
<number:0>
<number:1>
<number:123>
<number:123445>

-- test floating point numbers --
0
0.00
0.01
0.23
0123.0456
00123.990900
123.45
-- expect --
<number:0>
<number:0.00>
<number:0.01>
<number:0.23>
<number:0123.0456>
<number:00123.990900>
<number:123.45>

-- test hex numbers --
0x0
0x09
0xAA
0xaf
0X00
0XABCD00
-- expect --
<number:0x0>
<number:0x09>
<number:0xAA>
<number:0xaf>
<number:0X00>
<number:0XABCD00>

-- test exponents -- 
0.0e0
1e7
1.23e743
-- expect --
<number:0.0e0>
<number:1e7>
<number:1.23e743>


#-----------------------------------------------------------------------
# unary negative/positive numbers
#-----------------------------------------------------------------------

-- test unary no term error --
-
-- expect --
<ERROR:Missing expression after '-'>

-- test negative integers --
-123
-0
- 420
-- expect -- 
<prefix:<op:-><number:123>>
<prefix:<op:-><number:0>>
<prefix:<op:-><number:420>>

-- test positive integers --
+123
+0
+ 420
-- expect -- 
<prefix:<op:+><number:123>>
<prefix:<op:+><number:0>>
<prefix:<op:+><number:420>>

-- test negative floating point numbers --
-123.45
-0.02
-0023.00200
-- expect --
<prefix:<op:-><number:123.45>>
<prefix:<op:-><number:0.02>>
<prefix:<op:-><number:0023.00200>>

-- test positive floating point numbers --
+123.45
+0.234
+000.345
-- expect --
<prefix:<op:+><number:123.45>>
<prefix:<op:+><number:0.234>>
<prefix:<op:+><number:000.345>>

-- test negative hex numbers: -0xABcd --
-0xABcd
-0x00
-- expect --
<prefix:<op:-><number:0xABcd>>
<prefix:<op:-><number:0x00>>

-- test positive hex numbers --
+0x987654
+0x00
-- expect --
<prefix:<op:+><number:0x987654>>
<prefix:<op:+><number:0x00>>

-- test negative exponents -- 
-1.23e-45
-1.23e+45
-9e7
-9.13e4
-0e3
-0e0
-0.00e0
-- expect --
<prefix:<op:-><number:1.23e-45>>
<prefix:<op:-><number:1.23e+45>>
<prefix:<op:-><number:9e7>>
<prefix:<op:-><number:9.13e4>>
<prefix:<op:-><number:0e3>>
<prefix:<op:-><number:0e0>>
<prefix:<op:-><number:0.00e0>>

-- test positive exponents -- 
+0
+0.00
+1.23e+45
+1.23e-45
-- expect --
<prefix:<op:+><number:0>>
<prefix:<op:+><number:0.00>>
<prefix:<op:+><number:1.23e+45>>
<prefix:<op:+><number:1.23e-45>>

-- test multiple unary --
- - 16
+ + 17
-- expect --
<prefix:<op:-><prefix:<op:-><number:16>>>
<prefix:<op:+><prefix:<op:+><number:17>>>

-- test mixed multiple unary --
- + 19
+ - 20
-- expect --
<prefix:<op:-><prefix:<op:+><number:19>>>
<prefix:<op:+><prefix:<op:-><number:20>>>


#-----------------------------------------------------------------------
# TODO: unary auto increment/decrement operators: a++, ++a, a--, --a, etc.
#-----------------------------------------------------------------------



#-----------------------------------------------------------------------
# numerical binary operators
#-----------------------------------------------------------------------

-- test exponents - I have the power! -- 
10**2
30**3**2
-- expect --
<binary:<op:**><number:10><number:2>>
<binary:<op:**><number:30><binary:<op:**><number:3><number:2>>>

-- test addition -- 
10+20
30 + 40
1.2+3.4
4.5 + 5.6
0x20 + 0x40
-- expect --
<binary:<op:+><number:10><number:20>>
<binary:<op:+><number:30><number:40>>
<binary:<op:+><number:1.2><number:3.4>>
<binary:<op:+><number:4.5><number:5.6>>
<binary:<op:+><number:0x20><number:0x40>>

-- test addition with negative/positive numbers -- 
-10 + +20
+0x20 + -0x40
-- expect --
<binary:<op:+><prefix:<op:-><number:10>><prefix:<op:+><number:20>>>
<binary:<op:+><prefix:<op:+><number:0x20>><prefix:<op:-><number:0x40>>>

-- test subtraction -- 
10-20
30 - 40
1.2-3.4
4e5 - 5e6
0x40 - 0x20
-- expect --
<binary:<op:-><number:10><number:20>>
<binary:<op:-><number:30><number:40>>
<binary:<op:-><number:1.2><number:3.4>>
<binary:<op:-><number:4e5><number:5e6>>
<binary:<op:-><number:0x40><number:0x20>>

-- test subtraction with negative numbers -- 
-10 - -20
-- expect --
<binary:<op:-><prefix:<op:-><number:10>><prefix:<op:-><number:20>>>

-- test multiplication -- 
10*20
30 * 40
1.2*3.4
4e5 * 5e6
-- expect --
<binary:<op:*><number:10><number:20>>
<binary:<op:*><number:30><number:40>>
<binary:<op:*><number:1.2><number:3.4>>
<binary:<op:*><number:4e5><number:5e6>>

-- test multiplication with negative numbers -- 
-10 * -20
-- expect --
<binary:<op:*><prefix:<op:-><number:10>><prefix:<op:-><number:20>>>

-- test division -- 
10/20
30 / 40
1.2/3.4
4e5 / 5e6
-- expect --
<binary:<op:/><number:10><number:20>>
<binary:<op:/><number:30><number:40>>
<binary:<op:/><number:1.2><number:3.4>>
<binary:<op:/><number:4e5><number:5e6>>

-- test division with negative numbers -- 
-10 / -20
-- expect --
<binary:<op:/><prefix:<op:-><number:10>><prefix:<op:-><number:20>>>

-- test integer division -- 
10 div 20
1.2 div 3.4
4e5 div 5e6
-- expect --
<binary:<op:div><number:10><number:20>>
<binary:<op:div><number:1.2><number:3.4>>
<binary:<op:div><number:4e5><number:5e6>>

-- test integer modulus: % -- 
10%20
11 % 21
1.2 % 3.4
4e5 % 5e6
-- expect --
<binary:<op:%><number:10><number:20>>
<binary:<op:%><number:11><number:21>>
<binary:<op:%><number:1.2><number:3.4>>
<binary:<op:%><number:4e5><number:5e6>>

-- test integer modulus: mod -- 
10 mod 20
1.2 mod 3.4
4e5 mod 5e6
-- expect --
<binary:<op:mod><number:10><number:20>>
<binary:<op:mod><number:1.2><number:3.4>>
<binary:<op:mod><number:4e5><number:5e6>>


-- test equal --
10==20
30 == 40
-- expect --
<binary:<op:==><number:10><number:20>>
<binary:<op:==><number:30><number:40>>


-- test not equal --
10!=20
30 != 40
-- expect --
<binary:<op:!=><number:10><number:20>>
<binary:<op:!=><number:30><number:40>>

-- test less than --
10<20
30 < 40
-- expect --
<binary:<op:<><number:10><number:20>>
<binary:<op:<><number:30><number:40>>

-- test more than --
10>20
30 > 40
-- expect --
<binary:<op:>><number:10><number:20>>
<binary:<op:>><number:30><number:40>>

-- test less equal --
10<=20
30 <= 40
-- expect --
<binary:<op:<=><number:10><number:20>>
<binary:<op:<=><number:30><number:40>>

-- test more equal --
10>=20
30 >= 40
-- expect --
<binary:<op:>=><number:10><number:20>>
<binary:<op:>=><number:30><number:40>>

-- test compare --
10<=>20
30 <=> 40
-- expect --
<binary:<op:<=>><number:10><number:20>>
<binary:<op:<=>><number:30><number:40>>

-- test add equals --
10+=20
30+=40
-- expect --
<binary:<op:+=><number:10><number:20>>
<binary:<op:+=><number:30><number:40>>

-- test subtract equals --
10-=20
30-=40
-- expect --
<binary:<op:-=><number:10><number:20>>
<binary:<op:-=><number:30><number:40>>

-- test multiply equals --
10*=20
30*=40
-- expect --
<binary:<op:*=><number:10><number:20>>
<binary:<op:*=><number:30><number:40>>

-- test divide equals --
10/=20
30/=40
-- expect --
<binary:<op:/=><number:10><number:20>>
<binary:<op:/=><number:30><number:40>>





#-----------------------------------------------------------------------
# operator precedence
#-----------------------------------------------------------------------

-- test same precedence --
1 + 2 + 3
-- expect --
-- collapse --
<binary:
  <op:+>
  <binary:
    <op:+>
    <number:1>
    <number:2>
  >
  <number:3>
>

-- test more of the same precedence --
1 + 3 + 5 + 7 + 9
-- expect --
-- collapse --
<binary:
  <op:+>
  <binary:
    <op:+>
    <binary:
      <op:+>
      <binary:
        <op:+>
        <number:1>
        <number:3>
      >
      <number:5>
    >
    <number:7>
  >
  <number:9>
>

-- test increasing precedence --
2 + 4 * 6
-- expect --
-- collapse --
<binary:
  <op:+>
  <number:2>
  <binary:
    <op:*>
    <number:4>
    <number:6>
  >
>

-- test decreasing precedence --
2 * 4 + 6
-- expect --
-- collapse --
<binary:
  <op:+>
  <binary:
    <op:*>
    <number:2>
    <number:4>
  >
  <number:6>
>

-- test repeat increasing precedence --
2 > 3 + 5 * 7
-- expect --
-- collapse --
<binary:
  <op:>>
  <number:2>
  <binary:
    <op:+>
    <number:3>
    <binary:
      <op:*>
      <number:5>
      <number:7>
    >
  >
>

-- test repeat decreasing precedence --
11 * 13 + 17 < 19
-- expect --
-- collapse --
<binary:
  <op:<>
  <binary:
    <op:+>
    <binary:
      <op:*>
      <number:11>
      <number:13>
    >
    <number:17>
  >
  <number:19>
>


-- test increasing then decreasing precedence --
23 + 29 * 31 + 37 
-- expect --
-- collapse --
<binary:
  <op:+>
  <binary:
    <op:+>
    <number:23>
    <binary:
      <op:*>
      <number:29>
      <number:31>
    >
  >
  <number:37>
>


-- test decreasing then increasing precedence --
1 * 3 + 5 * 7
-- expect --
-- collapse --
<binary:
  <op:+>
  <binary:
    <op:*>
    <number:1>
    <number:3>
  >
  <binary:
    <op:*>
    <number:5>
    <number:7>
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

