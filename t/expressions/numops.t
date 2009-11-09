#============================================================= -*-perl-*-
#
# t/expressions/numbers.t
#
# Test script for numbers and numerical expressions.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    tests   => 36,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions';

test_expressions(
    debug     => $DEBUG,
    variables => {
        phi => 1.618,
        pi  => 3.142,
        e   => 2.718,
    },
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
0
1
123
123445

-- test floating point numbers --
0
0.00
0.01
0.23
0123.0456
00123.990900
123.45
-- expect --
0
0.00
0.01
0.23
0123.0456
00123.990900
123.45

-- test hex numbers --
0x0
0x09
0xAA
0xaf
0X00
0XABCD00
-- expect --
0x0
0x09
0xAA
0xaf
0X00
0XABCD00

-- test exponents -- 
0.0e0
1e7
1.23e743
-- expect --
0.0e0
1e7
1.23e743


#-----------------------------------------------------------------------
# unary negative/positive numbers
#-----------------------------------------------------------------------

-- test unary no term error --
-
-- expect --
<ERROR:Missing expression after '-'>

-- test negative integers --
-123
-0    # Note: negative zero becomes just zero
- 420
-- expect -- 
-123
0
-420


-- test positive integers --
+123
+0
+ 420
-- expect -- 
123
0
420

-- test negative floating point numbers --
-123.45
-0.02
-0023.00200    # leading and trailing zeroes will be removed
-- expect --
-123.45
-0.02
-23.002

-- test positive floating point numbers --
+123.45
+0.234
+000.345
-- expect --
123.45
0.234
000.345

-- test negative hex numbers: -0xABcd --
-- skip TODO: pre-parse hex numbers at tokenisation time --
-0xABcd     # this is borken because we parse the hex number as a string
-0x00       # which *doesn't* match against numlike / looks_like_number
-- expect --
-0xABcd
-0x00

-- test positive hex numbers --
# hmmm... that's strange... these work.
+0x987654   # borken for the same reason as above
+0x00       # we need to do a little extra work at tokenisation time
-- expect --
0x987654
0x00

-- test negative exponents -- 
-1.23e-45   # Perl doesn't expand this...
-1.23e+45
-9e7        # Perl expands this... I wonder if that's a Perl policy that works
-9.13e4     # the same on all platforms or if it depends on the C library?
-0e3
-0e0
-0.00e0
-- expect --
-1.23e-45
-1.23e+45
-90000000
-91300
0
0
0

-- test positive exponents -- 
+1.23e+45
+1.23e-45
-- expect --
1.23e+45
1.23e-45

-- test multiple unary --
- - 16
+ + 17
-- expect --
16
17

-- test mixed multiple unary --
- + 19
+ - 20
-- expect --
-19
-20


#-----------------------------------------------------------------------
# TODO: unary auto increment/decrement operators: a++, ++a, a--, --a, etc.
#-----------------------------------------------------------------------



#-----------------------------------------------------------------------
# numerical binary operators
#-----------------------------------------------------------------------

-- test exponents - I have the power! -- 
10**2
-- expect --
100

-- test addition -- 
10+20
30 + 40
1.2+3.4
4.5 + 5.6
-- expect --
30
70
4.6
10.1

-- test adding hex numbers --
-- skip TODO: numerify hex numbers at tokenisation time --
0x20 + 0x40
0x40 - 0x20
-- expect --
72
32

-- test addition with negative/positive numbers -- 
-10 + +20
-- expect --
10

-- test subtraction -- 
10-20
30 - 40
1.2-3.4
4e3 - 5e2    # 4000 - 500
-- expect --
-10
-10
-2.2
3500

-- test subtraction with negative numbers -- 
-10 - -20
-- expect --
10

-- test multiplication -- 
10*20
30 * 40
1.2*3.4
-- expect --
200
1200
4.08

-- test multiplication with negative numbers -- 
-10 * -20
-- expect --
200

-- test division -- 
20/10
30 / 40
3.6/1.2
2e3 / 1e2
-- expect --
2
0.75
3
20

-- test division with negative numbers -- 
-20 / -10
-- expect --
2

-- test integer division -- 
20 div 7
7.4 div 1.2
4e6 div 5e4
-- expect --
2
6
80

-- test integer modulus: % -- 
20%7
21 % 7
7.4 % 1.2
4e5 % 5e6
-- expect --
6
0
0
400000

-- test integer modulus: mod -- 
20 mod 7
21 mod 7
7.4 mod 1.2
4e5 mod 5e6
-- expect --
6
0
0
400000


#-----------------------------------------------------------------------
# expressions with variables
#-----------------------------------------------------------------------

-- test phi + pi --
phi + pi
-- expect --
4.76

-- test phi + pi * e --
phi + pi * e
-- expect --
10.157956


#-----------------------------------------------------------------------
# operator precedence
#-----------------------------------------------------------------------

-- test same precedence --
1 + 2 + 3
-- expect --
6

-- test more of the same precedence --
1 + 3 + 5 + 7 + 9
-- expect --
25

-- test increasing precedence --
2 + 4 * 6
-- expect --
26

-- test decreasing precedence --
2 * 4 + 6
-- expect --
14

-- test increasing then decreasing precedence --
2 + 3 * 4 + 5 
-- expect --
19

-- test decreasing then increasing precedence --
2 * 3 + 5 * 7
-- expect --
41




#-----------------------------------------------------------------------
# MORE TODO - need 'if' or '?' / ':' for these
#-----------------------------------------------------------------------

-- stop --


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


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

