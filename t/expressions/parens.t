#============================================================= -*-perl-*-
#
# t/expressions/parens.t
#
# Test script for parenthesised expressions.
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
    tests   => 8,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => DEBUG,
    variables => callsign,
);


__DATA__

-- test single grouped expression --
(1 + 10)
-- expect -- 
11

-- test multiple grouped expressions --
((2 + 2), (10 + 10))
-- expect -- 
420

-- test precedence override --
(2 + 3) * 4
-- expect -- 
20

-- test list context values --
[(1), (2, 3), ((4, 5), (6, 7))].join
-- expect --
1 2 3 4 5 6 7

-- test scalar assignment value --
a = ([1, 2, 3]); a.join
-- expect --
1 2 3

-- test scalar assignment string --
a = (4, 2, 0); a
-- expect --
420

-- test range --
(1 to 3)
-- expect --
123

-- test nested expressions --
((is x), ' ', (is y))
-- expect --
x-ray yankee

