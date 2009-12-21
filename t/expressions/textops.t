#============================================================= -*-perl-*-
#
# t/expressions/textops.t
#
# Test script for textual operators
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
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test string concatenation --
%% a ~ b
-- expect -- 
alphabravo

-- test chained string concatenation --
%% a ~ b ~ c
-- expect -- 
alphabravocharlie

-- test string concatenation onto command --
%% a ~ is { d e }
-- expect -- 
alphadeltaecho

-- test string concatenation assignment --
%% a ~= b; 'a: ' a
-- expect -- 
a: alphabravo

-- test string concatenation with single quotes --
%% 'foo' ~ 'bar'
-- expect --
foobar

-- test string concatenation with double quotes --
%% "$a $b " ~ "$c $d"
-- expect --
alpha bravo charlie delta



