#============================================================= -*-perl-*-
#
# t/commands/with.t
#
# Test script for the 'with' command.
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
    tests   => 9,
    debug   => 'Template::TT3::Context',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::HTML;

test_expect(
    full_error => 1,
    block     => 1,
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test with variables --
a: [% a %]
b: [% b %]
c: [% c %]
d: [% d %]
[% with a=x b=y -%]
a: [% a %]
b: [% b %]
c: [% c=z; c %]
d: [% d %]
[% end -%]
a: [% a %]
b: [% b %]
c: [% c %]
d: [% d %]
-- expect -- 
a: alpha
b: bravo
c: charlie
d: delta
a: x-ray
b: yankee
c: zulu
d: delta
a: alpha
b: bravo
c: charlie
d: delta

-- test with expressions in block form --
[%  with a = b ~ c d = e ~ f;
        "a: $a\nd: $d"
    end
%]
-- expect --
a: bravocharlie
d: echofoxtrot

-- test with arrows, commas and quotes --
[%  with a =>  'A', b => 'B';
        "a: $a\nb: $b"
    end
%]
-- expect --
a: A
b: B


-- test with braced block --
[%  with a=10 {
        'a: ' a
    }
%]
-- expect --
a: 10

-- test with hash expansion -- 
[% one = { a => 10, b => 20 };
   two = { c=30 d=40 };
   with %one %two;
      "a: $a\n";
      "b: $b\n";
      "c: $c\n";
      "d: $d\n";
   end;
%]
-- expect --
a: 10
b: 20
c: 30
d: 40


-- test with as infix operator --
[% "a is $a, b is $b, c is $c" with a=10 b=20 %]
-- expect --
a is 10, b is 20, c is charlie

-- test keyword detection --
[% with x=10 y=20 fill blah %]
-- expect --
TODO: fill blah

-- test with using naked dotted variables --
[% user = { name => 'Ford Prefect', email => 'ford@heart-of-gold.com' };
   with user.name, user.email;
      "name: $name\n";
      "email: $email\n";
   end;
%]
-- expect --
name: Ford Prefect
email: ford@heart-of-gold.com

-- test with using naked multi-dotted variables --
[% users = [ { name => 'Ford Prefect', email => 'ford@heart-of-gold.com' } ];
   with users.first.name, mailto=users.first.email;
      "name: $name\n";
      "email: $mailto\n";
   end;
%]
-- expect --
name: Ford Prefect
email: ford@heart-of-gold.com
