#============================================================= -*-perl-*-
#
# t/tags/control.t
#
# Test script for the [? control ?] tag
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
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test control tag with comment --
Hello [?# this whole tag is ignored because there is no 
          space before the first '#'
?]World
-- expect --
Hello World

-- test control tag with comment and pre chomping --
Hello
[?- # This line is ignored but only this line 
    # This line is ignored too
    # The pre/post chomp flags will eat whitespace around the tag
    a
    wizzle fribnitz
?] World
-- expect --
Hello World

-- test control tag with comment and post chomping --
Hello [? # This line is ignored but only this line -?]
World
-- expect --
Hello World
