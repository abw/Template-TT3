#============================================================= -*-perl-*-
#
# t/expressions/arrows.t
#
# Test script for => and -> arrows.
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
    block     => 1,
    debug     => $DEBUG,
    variables => callsign,
);

__DATA__

-- test create list using fat arrow --
%% arrow = a => 10;
%% arrow.join
-- expect --
a 10

-- test create list using fat arrow --
%% [a => 10].join
-- expect --
a 10

-- test multi arrows --
%% [a => b => c => 10].join
-- expect --
a b c 10

-- test multi arrows with quoted strings --
%% ['one' => "two" => "three four" => 10].join
-- expect --
one two three four 10
