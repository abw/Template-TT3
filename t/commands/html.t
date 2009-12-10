#============================================================= -*-perl-*-
#
# t/commands/html.t
#
# Test script for HTML expressions.
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
#    skip    => 'This is broken until keywords changes are localised',
    tests   => 13,
    debug   => 'Template::TT3::Element::HTML Template::TT3::Element::Control::HtmlElement',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::Element::HTML;

test_expect(
    block       => 1,
#    dump_tokens => $DEBUG,
    debug       => $DEBUG,
    variables   => callsign,
);

__DATA__

-- test html table --
[? HTML_CMDS -?]
[% table 'Hello World' %]
-- expect --
<table>Hello World</table>

-- test html table --
[?  HTML_CMDS -?]
[%  table {
        tr {
            td 'Hello World'
            td 'Hello Badger'
        }
    }
%]
-- expect --
<table><tr><td>Hello World</td><td>Hello Badger</td></tr></table>

-- test html generation with for loop --
[?  HTML_CMDS -?]
[%  menu_data = [
      [ 'index.html',   'Home'       ]
      [ 'about.html',   'About Us'   ]
      [ 'contact.html', 'Contact Us' ]
    ]
    
    ul {
        for menu_data {
            li a item.1
        }
    }
%]
-- expect --
-- collapse --
<ul>
  <li><a>Home</a>
  </li><li><a>About Us</a></li>
  <li><a>Contact Us</a></li>
</ul>


-- test html generation with [attributes] --
[? HTML_CMDS -?]
[% a[href='index.html'] 'Hello World' %]
-- expect --
<a href="index.html">Hello World</a>


-- test html generation with (attributes) --
[? HTML_CMDS -?]
[% a[href='index.html' class='menu'] 'Hello World' %]
-- expect --
<a class="menu" href="index.html">Hello World</a>

-- test html generation with dotted classes --
[? HTML_CMDS -?]
[% a.menu 'Hello World' %]
-- expect --
<a class="menu">Hello World</a>

-- test html generation with multi-dotted classes --
[? HTML_CMDS -?]
[% a.menu.hello 'Hello World' %]
-- expect --
<a class="menu hello">Hello World</a>

-- test html generation with hash ident --
[? HTML_CMDS -?]
[% a#menu 'Hello World' %]
-- expect --
<a id="menu">Hello World</a>

-- test html generation with dotted classes and hash ident --
[? HTML_CMDS -?]
[% a.foo.bar#menu 'Hello World' %]
-- expect --
<a class="foo bar" id="menu">Hello World</a>

-- test html generation with dotted classes, hash ident and attrs --
[? HTML_CMDS -?]
[% a[class='foo'].bar.baz#menu 'Hello World' %]
-- expect --
<a class="foo bar baz" id="menu">Hello World</a>

-- test html generation with duplicate id error --
[? HTML_CMDS -?]
[% a[id='foo'].bar.baz#menu 'Hello World' %]
-- expect --
<ERROR:HTML element id specified twice in a: foo / menu>

-- test full-blown html generation with for loop --
[?  HTML_CMDS -?]
[%  menu_data = [
      [ 'index.html',   'Home'       ]
      [ 'about.html',   'About Us'   ]
      [ 'contact.html', 'Contact Us' ]
    ]
    
    ul.menu {
        for menu_data {
            li a[href=item.0] item.1
        }
    }
%]
-- expect --
-- collapse --
<ul class="menu">
  <li><a href="index.html">Home</a></li>
  <li><a href="about.html">About Us</a></li>
  <li><a href="contact.html">Contact Us</a></li>
</ul>

-- test Remaining tests depend on grammar not being trampled --
-- skip --
-- expect --

-- stop --


-- test loading single HTML command --
[? HTML_CMDS a -?]
[% a b %]
-- expect --
<a>bravo</a>

-- test loading multiple HTML commands --
[? HTML_CMDS a b -?]
[% a b c %]
-- expect --
<a><b>charlie</b></a>

-- test loading HTML command with alias --
[? HTML_CMDS italic = i, bold = b -?]
[% italic bold a %]
-- expect --
<i><b>alpha</b></i>

-- test loading HTML command with 'as' alias --
[? HTML_CMDS i as italic, b as bold -?]
[% italic bold a %]
-- expect --
<i><b>alpha</b></i>

-- test id shortcut --
[? HTML_CMDS i as italic, b as bold -?]
[% italic#foo 'hello' %]
-- expect --
<i id="foo">hello</i>



