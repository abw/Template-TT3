#============================================================= -*-perl-*-
#
# t/commands/do.t
#
# Test script for the 'do' command.
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
    tests   => 7,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test a --
a
-- expect -- 
alpha

-- test do a --
do a
-- expect -- 
alpha

-- test inline do; a; b; end --
do; a; b; end
-- expect -- 
bravo

-- test inline do { c; d } --
do { c; d; }
-- expect -- 
delta

-- test inline do { a; b } c; d--
do { a; b; } c; ;;;   ; d e f
-- expect -- 
bravocharliedeltaechofoxtrot


-- test assign to do --
-- block --
foo = do;
  x y 
end
foo
-- expect --
yankee

-- test do side-effect --
-- block --
'y: ' do;
  x=99 y 
end
'  x: ' x
-- expect --
y: yankee  x: 99
