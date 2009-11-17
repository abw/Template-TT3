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
    skip    => 'abw is working on this at the moment',
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
# this should fail because it looks like a named block
[% block a %]
-- expect -- 
<ERROR:Missing block for 'block'.  End of file reached.>

-- test assignment to block .. end --
[% foo = block; b; c; end -%]
foo: [% foo %]
-- expect --
foo: bravocharlie

-- test named block --
[% block bar -%]
This is the bar block
[% end -%]
The end
-- expect --
The end

-- test block with args --
[% foo = block(name,@foo) { 'Hello ' name } -%]
greeting: [%# hello('World') %]
-- expect --
greeting: Hello World

-- start --
-- test named block --
[% block lovers; r.ucfirst ' and ' j.ucfirst; end %]