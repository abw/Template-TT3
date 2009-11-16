#============================================================= -*-perl-*-
#
# t/commands/fill.t
#
# Test script for the 'fill' command.
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
    tests   => 5,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test TODO: fill doesn't generate any output yet --
-- skip --

-- test fill foo --
fill foo
-- expect -- 
TODO: fill foo

-- test fill foo.tt3 --
fill foo.tt3
-- expect -- 
TODO: fill foo.tt3

-- test fill foo/bar.tt3 --
fill foo/bar.tt3
-- expect -- 
TODO: fill foo/bar.tt3

-- test fill foo .tt3 --
fill foo .tt3
-- expect -- 
# Note that the test_expressions() function automatically add '[%' and '%]'
# around the input text.  That's why we've got an additional '%]' at the end
<ERROR:unparsed tokens: .tt3 %]>

-- test fill .foo/bar --
fill .foo/bar
-- expect -- 
TODO: fill .foo/bar

-- test fill 'quoted' --
fill 'foo.bar'
-- expect --
TODO: fill foo.bar

-- test fill $a --
fill $a
-- expect --
TODO: fill alpha
