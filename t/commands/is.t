#============================================================= -*-perl-*-
#
# t/commands/is.t
#
# Test script for the 'is' command.
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
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test alpha --
is a;
-- expect -- 
alpha

-- test bravo --
is; b; end;
-- expect -- 
bravo

-- test charlie --
a is c; a
-- expect -- 
charlie

-- test delta --
a is; d; end; a
-- expect -- 
delta

-- test echo foxtrot golf --
a is { e f g } a
-- expect -- 
echofoxtrotgolf

-- test assign is --
a = is h; a
-- expect --
hotel

