#============================================================= -*-perl-*-
#
# t/commands/block.t
#
# Test script for the 'block' command.
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
    tests   => 13,
    debug   => 'Template::TT3::Element::Command::Block',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test block ... end --
[% block; a; end %]
-- expect -- 
alpha

-- test block { } --
[% block { a b c } %]
-- expect -- 
alphabravocharlie

-- test block with single expression --
# this should fail because it looks like a named block
[% block a %]
-- expect -- 
<ERROR:Missing block for 'block'.  End of file reached.>

-- test assignment to block .. end --
[% foo = block; b; c; end -%]
foo: [% foo %]
-- expect --
foo: bravocharlie

-- test named block --
[% block bar -%]
This is the bar block
[% end -%]
The end
-- expect --
The end

-- test block with args --
[% hello = block(name,@foo) { 'Hello ' name } -%]
greeting: [% hello('World') %]
-- expect --
greeting: Hello World

-- test named block --
[% block lovers; r.ucfirst ' and ' j.ucfirst; end %]

-- test runtime block sub --
[% foo = block(x,y) { 'x is ' x ' and y is ' y } -%]
foo(10, 20): [% foo(10, 20) %]
-- expect --
foo(10, 20): x is 10 and y is 20

-- test runtime block sub with list collector --
[% foo = block(x,y, @z) { 'x is ' x ', y is ' y ' and z is ' z.join(', ') } -%]
foo(10, 20, 30, 40): [% foo(10, 20, 30, 40) %]
-- expect --
foo(10, 20, 30, 40): x is 10, y is 20 and z is 30, 40

-- test runtime block sub with hash collector --
[% foo = block(x,y, %z) { 'x is ' x ', y is ' y ' and z has ' z.keys.join(', ') } -%]
foo(10, 20, a=30, b=40): [% foo(10, 20, a=30, b=40) %]
-- expect --
foo(10, 20, a=30, b=40): x is 10, y is 20 and z has a, b

-- test HTML element --
[%  html_element = block( name, %attrs, @content ) {
      '<' name;
      attrs.html_attrs;

      if content.size {
          '>' content.join('') '</' name '>'
      }
      else {
         '/>'
      }
    }
-%]
foo: [% html_element('foo') %]
bar: [% html_element('foo', 'bar', 'baz') %]
baz: [% html_element('foo', x=10, y=20, 'bar', 'baz') %]
-- expect --
foo: <foo/>
bar: <foo>barbaz</foo>
baz: <foo x="10" y="20">barbaz</foo>



-- test HTML element text style --
[%  html_element = block(name,@content) ~%]
        <[% name %]
        [%~ if content.size ~%]
            >
            [%~ content.join('') ~%]
            </[% name %]>
        [%~ end %]
        [%~ if not content.size ~%]
            />
        [%~ end %]
[%~ end ~%]

foo: [% html_element('foo') %]
bar: [% html_element('foo', 'bar', 'baz') %]

-- expect --
foo: <foo/>
bar: <foo>barbaz</foo>

-- test block subs --
%% hello = block(name)
Hello [% name %]!
%% end
%% hello('World')
%% hello('Badger')
-- expect --
Hello World!
Hello Badger!


         
         