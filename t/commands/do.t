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
    tests   => 5,
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
alphabravo

-- test inline do { a; b } --
do { a; b; }
-- expect -- 
alphabravo

-- test inline do { a; b } c; d--
do { a; b; } c; ;;;   ; d e f
-- expect -- 
alphabravocharliedeltaechofoxtrot


-- stop --
-- test block --
-- block --
block;
  x;
  y;
end;
-- expect --
x-rayyankee
