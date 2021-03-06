#============================================================= -*-perl-*-
#
# t/expressions/assign.t
#
# Test script for assignment expressions.
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
    debug   => 'Template::TT3::Context',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    verbose   => 1,
    debug     => $DEBUG,
    variables => callsign,
);

__DATA__

-- test assign new variable --
%% foo = 10; 'foo is '; foo
-- expect --
foo is 10

-- test assign existing variable --
%% 'a is ' a "\n"
%% a = 10; 'a is ' a
-- expect --
a is alpha
a is 10

-- test assign foo bar --
%% foo = 10
%% bar = foo
%% bar
-- expect --
10

-- test assign chain --
[%  foo = bar = baz = 10;  
    'foo: ' foo '  '
    'bar: ' bar '  '
    'baz: ' baz 
%]
-- expect --
foo: 10  bar: 10  baz: 10

-- test subroutine assignment --
%% bold(text) = "<b>$text</b>";  bold('hello world');
-- expect --
<b>hello world</b>

-- test subroutine calling previous subroutine --
-- block --
[%  one() = "this is one";
    two() = one(); 
    two();
%]
-- expect --
this is one

-- test subroutine calling previous subroutine with args --
-- block --
[%  x_is_y(x, y) = "$x is $y";
    pi_is(c) = x_is_y( pi => c ); 
    pi_is(3.14);
%]
-- expect --
pi is 3.14


-- test subroutine assignment with complex signature --
-- block --
[% html(name,%attrs,@content) = "<$name$attrs.html_attrs>$content.join</$name>";
   html( b => 'Hello World' ); "\n";
   html( 'a', href='index.html' 'Home Page' ); "\n";
   italic(%attrs,@content) = html('i',%attrs,@content);
   italic(class="emph", 'Hello Badger');
%]
-- expect --
<b>Hello World</b>
<a href="index.html">Home Page</a>
<i class="emph">Hello Badger</i>


-- test subroutine assignment with remerge --
-- block --
[%  one(name,%attrs,@content) = "[$name$attrs.html_attrs|$content.join]";
    two() = one('two', x=10,'Hello World'); 
    two();
%]
-- expect --
[two x="10"|Hello World]

#-----------------------------------------------------------------------
# assignment should be quiet when evaluated in text context (i.e. printed)
#-----------------------------------------------------------------------

-- test quiet assignment --
%% x = 10
x: [% x %]
-- expect --
x: 10

-- test quiet assignment in block --
%% block foo { x = 20; "x is $x" }; fill foo
-- expect --
x is 20

-- test quiet assignment in if --
%% if a { x = 30; "x is $x" }
-- expect --
x is 30

-- test quiet assignment in for --
%% for y in 40 to 41 { x = y+1; "x is $x\n" }
-- expect --
x is 41
x is 42



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
# Textmate: is the cheese on toast

