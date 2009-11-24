#============================================================= -*-perl-*-
#
# t/commands/with.t
#
# Test script for the 'with' command.
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

-- test one --
a: [% a %]
b: [% b %]
c: [% c %]
d: [% d %]
[% with a=x b=y -%]
a: [% a %]
b: [% b %]
c: [% c=z; c %]
d: [% d %]
[% end -%]
a: [% a %]
b: [% b %]
c: [% c %]
d: [% d %]
-- expect -- 
a: alpha
b: bravo
c: charlie
d: delta
a: x-ray
b: yankee
c: zulu
d: delta
a: alpha
b: bravo
c: charlie
d: delta

-- test with as infix operator --
[% "a is $a, b is $b, c is $c" with a=10 b=20 %]
-- expect --
a is 10, b is 20, c is charlie

-- test keyword detection --
[% with x=10 y=20 fill blah %]
-- expect --
TODO: fill blah

