#============================================================= -*-perl-*-
#
# t/tags/outline.t
#
# Test script for the outline tag
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

#use Badger::Debug 
#    modules => 'Template::TT3::Scanner';

use Template::TT3::Test 
    tests   => 2,
    debug   => 'Template::TT3::Tag::Outline Template::TT3::Scanner',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test outline --
before
%% a
after
-- expect --
before
alphaafter

-- test multi outline --
before
%% a b
%% c
after
-- expect --
before
alphabravocharlieafter

