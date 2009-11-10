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
    tests   => 4,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test string concatenation --
a ~ b
-- expect -- 
alphabravo

-- test chained string concatenation --
a ~ b ~ c
-- expect -- 
alphabravocharlie

-- test string concatenation onto command --
a ~ is { d e }
-- expect -- 
alphadeltaecho

-- test string concatenation assignment --
a ~= b; 'a: ' a
-- expect -- 
a: alphabravo


