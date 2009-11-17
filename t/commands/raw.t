#============================================================= -*-perl-*-
#
# t/commands/raw.t
#
# Test script for the 'raw' command.
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

use Template::TT3::HTML;

test_expect(
    debug     => $DEBUG,
    variables => {
        company => 'Marks & Spencer',
    },
);


__DATA__

-- test html mode --
-- method html --
<b>[% company %]</b>
-- expect -- 
&lt;b&gt;Marks &amp; Spencer&lt;/b&gt;

-- test html mode with is block --
-- method html --
[% is %]<b>[% company %]</b>[% end %]
-- expect -- 
&lt;b&gt;Marks &amp; Spencer&lt;/b&gt;

-- test html mode with raw block --
-- method html --
[% raw %]<b>[% company %]</b>[% end %]
-- expect -- 
<b>Marks & Spencer</b>

-- test html mode with raw braced block --
-- method html --
[% raw { '<b>' company '</b>' } %]
-- expect -- 
<b>Marks & Spencer</b>

