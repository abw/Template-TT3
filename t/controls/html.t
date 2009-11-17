#============================================================= -*-perl-*-
#
# t/controls/html.t
#
# Test script for HTML control directive.
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
#    modules => 'Badger::Factory Template::TT3::Element::Control::HTML';

use Template::TT3::Test 
    tests   => 7,
    debug   => 'Template::TT3::Tag',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::HTML;
my $vars = callsign;
$vars->{ company } = 'Marks & Spencer';

test_expect(
#    method    => 'html',
    variables => $vars,
    debug     => $DEBUG,
);

__DATA__

-- test text as text --
<b>[% company %]</b>
-- expect --
# Oh dear!  That ampersand is not valid in HTML.
<b>Marks & Spencer</b>

-- test text with company.html --
<b>[% company.html %]</b>
-- expect --
# The .html vmethod can be used to html encode the data.  It's just a bit
# of a pain having to remember to add it every time.
<b>Marks &amp; Spencer</b>

-- test text as html --
-- method html --
# The -- method html -- directive above tells the test engine to ask the 
# template for html output instead of plain text.  Each expression now
# yields an HTML encoded version of its text output.  In effect, we've 
# automatically added a '.html' to every expression.  
<b>[% company %]</b>
-- expect --
# Alas, this rule applies to all expressions (including text expressions,
# i.e. text chunks) - which we probably didn't want.
&lt;b&gt;Marks &amp; Spencer&lt;/b&gt;

-- test HTML on --
-- method html --
# The [? HTML on -?] control directive tells the scanner that all text chunks
# should generate HTML elements instead of text elements (NOTE: We use 
# 'element' to mean 'node in the compiled template tree', not an HTML element 
# tag like '<foo>'.  So a text element is just a chunk of text and an HTML 
# element is just a chunk of HTML).  When you ask a text element for html(), 
# it returns an HTML encoded version of its text.  But when you ask an HTML
# element for html(), it simply returns its text - it's already HTML.  The 
# end result is that our dynamically generated data is HTML encoded, but 
# our raw text isn't.
[? HTML on -?]
<b>[% company %]</b>
-- expect --
# Phew! Now the right bits get encoded.
<b>Marks &amp; Spencer</b>


-- test double encoding problem --
-- method html --
[? HTML on -?]
# Of course, it's not always that simple.  Because '.html' is effectively
# being added to every expression, something like: [% a = b; a %] becomes
# [% a = b.html; a.html %].  Double encoding blues!
#
# NOTE: this can be addressed by giving the 'is' (and every other block)
# element an explicit html() method.  I just haven't figure out the best
# way to do that generically yet
#
[% a is %]<b>[% company %]</b>[% end -%]
a: [% a %]
-- expect --
# Oh flippetty!  Now we've got double encoding again.
a: &lt;b&gt;Marks &amp; Spencer&lt;/b&gt;


-- test introducing the 'raw' block --
-- method html --
# Introducing the 'raw' block which defeats any internal HTML encoding.
# So even though we've got -- method html -- set (witness the encoding of 
# the '> About' text, the content of the raw block isn't HTML encoded.  Of
# course, this means we're back to adding .html onto the company variable
# because it no longer happens automatically.
[% raw %]<b>[% company.html %]</b>[% end %] > About
-- expect --
<b>Marks &amp; Spencer</b> &gt; About


-- test nested HTML with raw block --
-- method html --
# You've got to be careful because encoding can happen at any time.  
# In this example, we we assign the output of a raw block to 'b'. 
# However, we must also remember to use 'raw' when displaying the 
# variable 'b' or it will get encoded.
# gets encoded
[? HTML on -?]
[% b is raw %]<b>[% company.html %]</b>[% end -%]
b: [% b %]
raw b: [% raw b %]
-- expect --
# This is bad - we've got double encoding now on the ampersand in the 
# company name now. 
b: &lt;b&gt;Marks &amp;amp; Spencer&lt;/b&gt;
# But this is correct!  Yay!
raw b: <b>Marks &amp; Spencer</b>

-- stop --
-- test nested HTML with raw block evaluation --
-- method html --
[? HTML on -?]
# This whole HTML business is rather flaky because things inside blocks
# always gets 
[% c is %]<b>[% company %]</b>[% end -%]
c: [% c %]
raw c: [% raw c %]
-- expect --
# well, we expected this to be wrong
c: &lt;b&gt;Marks &amp;amp; Spencer&lt;/b&gt;
# But this works
raw c: <b>Marks &amp; Spencer</b>


