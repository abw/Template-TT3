#============================================================= -*-perl-*-
#
# t/commands/just.t
#
# Test script for the 'just' command.
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

use Template::TT3::HTML;

test_expect(
    block     => 1,
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test just variables --
a: [% a %]
b: [% b %]
c: [% c %]
[% just a=x b=y -%]
a: [% a %]
b: [% b %]
c: [% c.defined %]
[% end -%]
a: [% a %]
b: [% b %]
c: [% c %]
-- expect -- 
a: alpha
b: bravo
c: charlie
a: x-ray
b: yankee
c: 0
a: alpha
b: bravo
c: charlie

-- test with naked variables --
[% just a %]
a: [% a %]
b: [% b !! '<undef>' %]
[% end %]
-- expect --
a: alpha
b: <undef>

-- test with as infix operator --
[% "a is $a, b is $b, c is $c.defined" just a=10 b=20 %]
-- expect --
a is 10, b is 20, c is 0

-- test keyword detection --
[% just x=10 y=20 fill blah %]
-- expect --
TODO: fill blah

