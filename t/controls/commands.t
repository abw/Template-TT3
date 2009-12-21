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
    tests   => 7,
    debug   => 'Template::TT3::Tag',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::HTML;

our $vars = callsign;

test_expect(
#    verbose   => 1,
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test hello command before loading --
[% hello %]
-- expect --
<ERROR:Missing value: hello>

-- test using COMMANDS to load hello --
[% hello = 'Hi'-%]
[% hello %]
[? COMMANDS hello -?]
[% hello %]
-- expect --
Hi
Hello World!

-- test using COMMANDS with an alias --
[? COMMANDS hey = hello -?]
[% hey %]
-- expect --
Hello World!

-- test using COMMANDS with an 'as' alias --
[? COMMANDS hello as wazzup -?]
[% wazzup %]
-- expect --
Hello World!

-- test hello html mode --
-- method html --
[? COMMANDS hello -?]
[% hello %]
-- expect --
<b>Hello World!</b>

-- test multiple commands --
[? COMMANDS wrapper hello -?]
[% wrapper bold hello; block bold "<b>$content</b>" %]
-- expect --
<b>Hello World!</b>

-- test multiple commands with aliases --
[? COMMANDS wrapper as wrap, hello as hi -?]
[% hi wrap bold ; block bold "<b>$content</b>" %]
-- expect --
<b>Hello World!</b>
