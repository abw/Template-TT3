#============================================================= -*-perl-*-
#
# t/expressions/ternary.t
#
# Test script for ternary expressions.
#
# Run with -h option for help.
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
    tests   => 9,
    debug   => 'Template::TT3::Operator::Ternary',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    verbose   => 1,
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test ternary operator with simple vars --
%% a ? b : c
-- expect -- 
bravo

-- test ternary operator with complex test --
%% a.length < 10 ? d : e
-- expect -- 
delta

-- test ternary operator with complex first expression --
%% a ? f ~ g : h
-- expect -- 
foxtrotgolf

-- test ternary operator with complex second expression --
%% a.length > 20 ? i : [j k l].join(', ')
-- expect -- 
juliet, kilo, lima

-- test nested ternary operators --
%% m ? n ? o ? p : q : r : s
-- expect -- 
papa

-- test nested ternary operators with parens --
%% m ? (n ? (o ? p : q) : r) : s
-- expect -- 
papa

-- test ternary operator with missing first expression --
%% a ? 
-- error -- 
TT3 syntax error at line 1 of "ternary operator with missing first expression" test:
    Error: Missing expression for '?'.  End of file reached.
   Source: %% a ?
                 ^ here

-- test ternary operator with missing colon --
%% a ? b
-- error -- 
TT3 syntax error at line 1 of "ternary operator with missing colon" test:
    Error: Missing ':' for '?'.  End of file reached.
   Source: %% a ? b
                   ^ here

-- test ternary operator with missing second expression --
%% a ? b :
-- error -- 
TT3 syntax error at line 1 of "ternary operator with missing second expression" test:
    Error: Missing expression for ':'.  End of file reached.
   Source: %% a ? b :
                     ^ here