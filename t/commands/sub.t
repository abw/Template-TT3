#============================================================= -*-perl-*-
#
# t/commands/sub.t
#
# Test script for the 'sub' command.
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
    tests   => 21,
    debug   => 'Template::TT3::Element::Command::Sub',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test inline sub --
[% sub; a; end %]
-- expect -- 
alpha

-- test inline sub returns last value --
[% sub; a; b; end %]
-- expect -- 
bravo

-- test name equals anon sub --
[% foo = sub; a; end; foo() %]
-- expect -- 
alpha

-- test named sub --
[% sub foo; a; b; end; foo() %]
-- expect -- 
bravo

-- test named sub with arg --
[% sub inc(a) a + 1 -%]
two: [% inc(1) %]
-- expect -- 
two: 2

-- test named sub with args --
[% sub add(a,b) a + b -%]
three: [% add(1,2) %]
-- expect -- 
three: 3

-- test named sub with braces --
[%  sub add(a,b) {
        a, b, a + b, a - b
    }
-%]
four: [% add(6,2) %]
-- expect -- 
four: 4

-- test assignment to sub with braces --
[%  add = sub(a,b) {
        a, b, a / b
    }
-%]
five: [% add(20,4) %]
-- expect -- 
five: 5

-- test sub with too many args --
[%  sub foo(a, b) { "a=$a  b=$b" } -%]
foo(10, 20, 30, 40): [% foo(10, 20, 30, 40) %]
-- expect --
<ERROR:Unexpected positional arguments in call to foo(): 30, 40>

-- test sub with too many args in the wrong order --
[%  sub foo(a, b) { "a=$a  b=$b" } -%]
foo(10, 20, a=30, b=40): [% foo(10, 20, a=30, b=40) %]
-- expect --
<ERROR:Unexpected positional arguments in call to foo(): 10, 20>

-- test sub with list collector #1 --
[%  sub foo(a, b, @c) {  "a=$a  b=$b  c=[$c.join]" } -%]
foo(10, 20, 30, 40): [% foo(10, 20, 30, 40) %]
-- expect --
foo(10, 20, 30, 40): a=10  b=20  c=[30 40]

-- test sub with list collector #2 --
[%  sub foo(a, b, @c) {  "a=$a  b=$b  c=[$c.join]" } -%]
foo(b=10, a=20, 30, 40): [% foo(b=10, a=20, 30, 40) %]
-- expect --
foo(b=10, a=20, 30, 40): a=20  b=10  c=[30 40]

-- test sub with list collector #3 --
[%  sub foo(a, b, @c) {  "a=$a  b=$b  c=[$c.join]" } -%]
foo(30, 40, b=20, a=10, 50, 60): [% foo(30, 40, b=20, a=10, 50, 60) %]
-- expect --
foo(30, 40, b=20, a=10, 50, 60): a=10  b=20  c=[30 40 50 60]

-- test sub with hash collector #1 --
[%  sub foo(a, b, %c) { "a=$a  b=$b  c={$c.as_text}" } -%]
foo(10, 20, c=30, d=40): [% foo(10, 20, c=30, d=40) %]
-- expect --
foo(10, 20, c=30, d=40): a=10  b=20  c={c=30, d=40}

-- test sub with hash collector #2 --
[%  sub foo(a, b, %c) { "a=$a  b=$b  c={$c.as_text}" } -%]
foo(b=20, a=10, c=30, d=40): [% foo(b=20, a=10, c=30, d=40) %]
-- expect --
foo(b=20, a=10, c=30, d=40): a=10  b=20  c={c=30, d=40}

-- test sub with hash collector #3 --
[%  sub foo(a, b, %c) { "a=$a  b=$b  c={$c.as_text}" } -%]
foo(b=20, a=10, 30, 40): [% foo(b=20, a=10, 30, 40) %]
-- expect --
<ERROR:Unexpected positional arguments in call to foo(): 30, 40>

-- test sub with hash collector #4 --
[%  sub foo(a, b, %c) { "a=$a  b=$b  c={$c.as_text}" } -%]
foo(30, 40, b=20, a=10, c=50, d=60): [% foo(30, 40, b=20, a=10, c=50, d=60) %]
-- expect --
<ERROR:Unexpected positional arguments in call to foo(): 30, 40>

-- test sub with hash collector #5 --
[%  sub foo(a, b, %c) { "a=$a  b=$b  c={$c.as_text}" } -%]
foo(c=30, d=40, b=20, a=10, e=50, f=60): [% foo(c=30, d=40, b=20, a=10, e=50, f=60) %]
-- expect --
foo(c=30, d=40, b=20, a=10, e=50, f=60): a=10  b=20  c={c=30, d=40, e=50, f=60}


-- test sub with string arguments --
[% sub hello(name) "Hello $name"; hello('World') %]
-- expect --
Hello World

-- test sub with expression arguments --
[% sub hello(name) "Hello $name"; hello('Wor' ~ 'ld') %]
-- expect --
Hello World

-- test sub with command arguments --
[% sub hello(name) "Hello $name"; hello(if a b else c) %]
-- expect --
Hello bravo

