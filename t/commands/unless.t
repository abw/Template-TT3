#============================================================= -*-perl-*-
#
# t/commands/unless.t
#
# Test script for the 'unless' command.
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
    tests   => 2,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    block     => 1,
    verbose   => 1,
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test if a b --
%% unless not a b
-- expect -- 
bravo

-- test if a { b } --
%% unless a b else c
-- expect -- 
charlie

