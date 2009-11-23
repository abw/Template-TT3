#============================================================= -*-perl-*-
#
# t/commands/for.t
#
# Test script for the 'for' command.
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
    tests   => 12,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

my $vars = callsign;
$vars->{ foo } = 10;
$vars->{ bar } = 20;

test_expressions(
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test for [a b] --
for [a, b]; 'item: '; item; '  '; end; 'done'
-- expect -- 
item: alpha  item: bravo  done

-- test list generator --
[item * 3 for [1, 3, 5]].join
-- expect --
3 9 15

-- test list generator with guard --
-- block --
[   for [1, 2, 3, 4, 5, 6];
        if item < 5;
            item * 2;
        end;
    end 
].join
-- expect --
2 4 6 8

-- test list generator with braces --
-- block --
[   for [1, 2, 3, 4, 5, 6] {
        if item < 5 {
            item * 2
        }
    }
].join
-- expect --
2 4 6 8

-- test list generator with single block expressions --
#-- dump_tokens --
-- block --
[   for [1, 2, 3, 4, 5, 6] 
        if item < 5
            item * 2
].join
-- expect --
2 4 6 8

-- test list generator with guard in side-effect --
-- block --
[   item * 3 
        if item < 5
            for [1, 2, 3, 4, 5, 6]
].join
-- expect --
3 6 9 12

-- test undefined value --
-- block --
for failage yak
-- expect --
<ERROR:"failage" is undefined>

-- test for else --
-- block --
l = [ ]; for l; item; else; 'no items'; end
-- expect --
no items

-- test if/for/else true and empty --
-- block --
list = [ ]; 
if a
  for list
     item
  else
    'no items'
else
  'no alpha'
-- expect --
no items

-- test if/for/else false and empty --
-- block --
list = [ ]; 
if not a
  for list
     item
  else
    'no items'
else
  'no alpha'
-- expect --
no alpha

-- test if/for/else true and full --
-- block --
'<'
list = [ b c ]; 
if a
  for list
     ' * ' ~ item
  else
    'no items'
else
  'no alpha'
'>'
-- expect --
< * bravo * charlie>

-- test illegal follow declaration --
# TODO: create a custom command in t/lib which is deliberately broken
-- skip this requires the 'For' command to be broken --
for x y fill z;
-- expect --
<ERROR:'fill' cannot follow 'for'>


