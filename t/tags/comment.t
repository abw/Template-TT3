#============================================================= -*-perl-*-
#
# t/tags/comment.t
#
# Test script for the [# comment #] tag
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

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test Hello World pre space --
Hello [# this is ignored #]World
-- expect --
Hello World

-- test Hello World post space  --
Hello[# this is also ignored #] World
-- expect --
Hello World

-- test multi-line comment --
# Be careful about not putting the closing #] tag at the start of the lines
# as the test framework strips any line starting with '#' (like this one)
Hello[# this is a multi
        line comment
     #] World
-- expect --
Hello World

-- test comment include other tags --
[% name = 'World' %]Hello[# this is a multi line comment
                            including [% other tags %] like [? this ?] 
                         #] [% name %]
-- expect --
Hello World


