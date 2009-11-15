#============================================================= -*-perl-*-
#
# t/controls/tags.t
#
# Test script for TAGS control directive.
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
    skip    => 'TAGS control not implemented yet',
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test one --
Hello [% a %]
-- expect --
Hello alpha

-- test tags single string --
-- dump_tokens --
BEFORE
[? TAGS '<* *>' -?]
Hello <* a *>
-- expect --
BEFORE
Hello alpha

-- test tags list ref --
[? TAGS ['<*' '*>'] -?]
Hello <* b *>
-- expect --
Hello bravo

-- test tags assign string --
[? TAGS = '<* *>' -?]
Hello <* c *>
-- expect --
Hello charlie

-- test tags list ref --
[? TAGS = ['<*' '*>'] -?]
Hello <* d *>
-- expect --
Hello delta

-- test tags list ref --
[? TAGS off -?]
Hello <* e *>
[? TAGS on -?]
Hello <* e *>
-- expect --
Hello <* e *>
Hello echo


