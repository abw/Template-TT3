#============================================================= -*-perl-*-
#
# t/commands/decode.t
#
# Test script for the 'decode' command.
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
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test decode html --
[% decode html -%]
&lt;foo&gt;
[% end -%]
-- expect -- 
<foo>

-- test bad decoder --
[% decode some_funky_shit -%]
<foo>
[% end -%]
-- expect -- 
<ERROR:Invalid decoder specified for decode command: codec not found: some_funky_shit>