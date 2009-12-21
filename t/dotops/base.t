#============================================================= -*-perl-*-
#
# t/dotops/base.t
#
# Test script for the core set of dotops provided by the T::TT3::Type 
# base class.
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
    tests   => 8,
    debug   => 'Template::TT3::Template Template::TT3::Variables',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test a.defined --
%% a.defined
-- expect --
1

-- test a.true --
%% a.true
-- expect --
alpha

-- test a.false --
%% a.false
-- expect --
0

-- test a.hush --
%% '[' a.hush ']'
-- expect --
[]

-- test undef.defined --
%% undef.defined
-- expect --
0

-- test undef.true --
%% undef.true
-- expect --
0

-- test undef.false --
%% undef.false
-- expect --
1

-- test undef.hush --
%% '[' undef.hush ']'
-- expect --
[]

