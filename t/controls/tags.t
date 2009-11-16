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
    tests   => 15,
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

-- test tags single string --
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

-- test tags equals string --
[? TAGS = '<* *>' -?]
Hello <* c *>
-- expect --
Hello charlie

-- test tags equals list ref --
[? TAGS = ['<*' '*>'] -?]
Hello <* d *>
-- expect --
Hello delta

-- test tags are --
[? TAGS are ['<*' '*>'] -?]
Hello <* e *>
-- expect --
Hello echo

-- test "tags is" is grammatically incorrect --
[? TAGS is ['!*' '*!']   # I am illiterate -?]
Hello !* e *!
-- expect --
Hello echo

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

-- test multiple tags --
[? TAGS {
     inline  = '<* *>'
     comment = '<# #>'
   }
-?]
Hello [% i %]
Hello <* i *>
Hello [# i #]
Hello <# i #>!
-- expect --
Hello [% i %]
Hello india
Hello [# i #]
Hello !

-- test dotted tags --
[? TAGS.inline '<* *>' -?]
Romeo and [% j.ucfirst %]
Romeo and <* j.ucfirst *>
-- expect --
Romeo and [% j.ucfirst %]
Romeo and Juliet

-- test dotted tags --
[? TAGS.comment '<* *>' -?]
Romeo and [% j.ucfirst %] are lovers
Romeo and <* j.ucfirst *> are lovers
-- expect --
Romeo and Juliet are lovers
Romeo and  are lovers

-- test dotted tags with invalid name --
[? TAGS.cheese '<* *>' -?]
Romeo and [% j.ucfirst %] are lovers
-- expect --
<ERROR:Invalid tags specified: cheese>

    

