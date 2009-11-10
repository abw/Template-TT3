#============================================================= -*-perl-*-
#
# t/expressions/boolops.t
#
# Test script for boolean expressions.
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
    tests   => 15,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test boolean comparison && with true LHS --
a && b
-- expect -- 
bravo

-- test boolean comparison && with zero LHS --
a = 0; a && b
-- expect -- 
0

-- test boolean comparison && with blank LHS --
a = ''; a && b; c
-- expect -- 
charlie

-- test boolean comparison || with true LHS --
a || b
-- expect -- 
alpha

-- test boolean comparison || with false LHS --
a = 0; a || b
-- expect -- 
bravo

-- test boolean comparison !! with true LHS --
a !! b
-- expect -- 
alpha

-- test boolean comparison !! with false LHS --
a = 0; a !! b
-- expect -- 
0

-- test boolean comparison !! with undef LHS --
nothing !! b
-- expect -- 
bravo

-- test boolean assignment &&= with true LHS--
a &&= b; 'a: '; a;
-- expect --
a: bravo

-- test boolean assignment &&= with false LHS--
a = 0; a &&= b; 'a: '; a;
-- expect --
a: 0

-- test boolean assignment ||= with true LHS --
a ||= b; 'a: '; a;
-- expect --
a: alpha

-- test boolean assignment ||= with false LHS --
a = 0; a ||= b; 'a: '; a;
-- expect --
a: bravo

-- test boolean assignment !!= with true LHS --
a !!= b; 'a: '; a;
-- expect --
a: alpha

-- test boolean assignment ||= with false LHS --
a = 0; a !!= b; 'a: '; a;
-- expect --
a: 0

-- test boolean assignment ||= with undef LHS --
zip !!= b; 'zip: '; zip;
-- expect --
zip: bravo
