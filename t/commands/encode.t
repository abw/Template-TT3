#============================================================= -*-perl-*-
#
# t/commands/encode.t
#
# Test script for the 'encode' command.
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

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test encode html --
[% encode html -%]
<foo>
[% end -%]
-- expect -- 
&lt;foo&gt;

-- test encode base64 --
[% encode base64 -%]
Hello World
[% end -%]
-- expect -- 
SGVsbG8gV29ybGQK

-- test bad encoder --
[% encode some_funky_shit -%]
<foo>
[% end -%]
-- expect -- 
<ERROR:Invalid encoder specified for encode command: codec not found: some_funky_shit>

