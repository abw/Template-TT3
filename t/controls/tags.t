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

#use Badger::Debug
#    modules => 'Template::TT3::Tag';

use Template::TT3::Test 
    tests   => 10,
    debug   => 'Template::TT3::Tag',
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

-- test tags invalid --
[? TAGS invalid -?]
Hello World
-- expect --
<ERROR:Undefined value returned by TAGS expression: invalid>

# TAGS control isn't implemented yet

-- test tags single string --
#-- dump_tokens --
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

-- test tags are --
[? TAGS are ['<*' '*>'] -?]
Hello <* e *>
-- expect --
Hello echo

#-- start --

-- test tags off --
[? TAGS off -?]
Hello [% f %]
-- expect --
Hello [% f %]

-- test tags off/on --
[? TAGS off -?]
Hello [% f %]
[? TAGS on -?]
Hello [% f %]
-- expect --
Hello [% f %]
Hello foxtrot

-- test tags get restored to previous state --
[? TAGS '<* *>' -?]
<* h.ucfirst *> California
[? TAGS off -?]
<* h.ucfirst *> California
[? TAGS on -?]
<* h.ucfirst *> California
-- expect --
Hotel California
<* h.ucfirst *> California
Hotel California


