#============================================================= -*-perl-*-
#
# t/expressions/signatures.t
#
# Test script for function signatures.
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
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test block with single arg --
-- block --
hello = block(name) { 'Hello ' name }; 
hello('World')
-- expect --
Hello World

-- test block with list arg --
-- block --
hello = block(@foo) { 'Hello ' foo.join(' and ') }; 
hello('World', 'Badger')
-- expect --
Hello World and Badger

-- test multiple list arg error --
foo = block(@foo, @bar) { }
-- expect --
<ERROR:Duplicate '@' argument in signature for block(): @bar>

-- test multiple list arg in named block --
block wiz(@foo, @bar) { }
-- expect --
<ERROR:Duplicate '@' argument in signature for wiz(): @bar>

-- test hash collector --
-- block --
wiz = block(%foo) { 'hello' foo.html_attrs };
'wiz: ' wiz(x=10, y=20)
-- expect --
wiz: hello x="10" y="20"

-- test hash collector keys --
-- block --
foo = block(%hash) "You called foo() with $hash.keys.sort.join";
foo(a=10,b=20);
-- expect --
You called foo() with a b




