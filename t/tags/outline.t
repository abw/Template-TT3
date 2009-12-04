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
    tests   => 4,
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

-- test if outline --
#-- dump_tokens --
alpha
%% if 1
bravo
%% end
charlie
-- expect --
alpha
bravo
charlie

-- test if outline with trailing spaces and comments --
#-- skip work to do on outline tags --
# outline tags currently consume the newline end-of-tag token when they
# much whitespace and comments.
alpha
%% if 1        # this is a comment
bravo
# there are trailing spaces on the end of the next line
%% end   
charlie
-- expect --
alpha
bravo
charlie
