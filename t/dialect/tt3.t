#============================================================= -*-perl-*-
#
# t/dialect/tt3.t
#
# Test script for the TT3 dialect.
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
    tests   => 1,
    debug   => 'Template::TT3::Scanner Template::TT3::Dialect Template::TT3::Dialects',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    block     => 1,
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test a --
a: [% a %]
-- expect --
a: alpha
