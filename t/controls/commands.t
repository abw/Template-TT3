#============================================================= -*-perl-*-
#
# t/controls/commands.t
#
# Test script for COMMANDS control directive.
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
    tests   => 3,
    debug   => 'Template::TT3::Tag',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::HTML;

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test hello command before loading --
[% hello %]
-- expect --
<ERROR:"hello" is undefined>

-- test using COMMANDS to load hello --
[% hello = 'Hi'-%]
[% hello %]
[? COMMANDS hello -?]
[% hello %]
-- expect --
Hi
Hello World!

-- test hello html mode --
-- method html --
[? COMMANDS hello -?]
[% hello %]
-- expect --
<b>Hello World!</b>
