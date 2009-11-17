#============================================================= -*-perl-*-
#
# t/commands/block.t
#
# Test script for the 'block' command.
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
    tests   => 4,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test block ... end --
[% block; a; end %]
-- expect -- 
alpha

-- test block { } --
[% block { a b c } %]
-- expect -- 
alphabravocharlie

-- test block with single expression --
[% block a %]
-- expect -- 
alpha

-- test assignment to block .. end --
[% foo = block; b; c; end -%]
foo: [% foo %]
-- expect --
foo: bravocharlie

