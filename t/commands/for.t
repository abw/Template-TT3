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
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    tests   => 22,
    import  => 'test_expect callsign';

use Template::TT3::Element::Command::For;

my $vars = callsign;
$vars->{ foo } = 10;
$vars->{ bar } = 20;
$vars->{ wiz } = { waz => undef };
$vars->{ soz } = "I'm sorry Dave, I'm afraid I can't do that.",

test_expect(
    block     => 1,
    verbose   => 1,
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test for list --
[% list = [a,b];
   for list; 
     "item: $item\n";
   end;
%]
-- expect -- 
item: alpha
item: bravo

-- test for x in [a,b] --
[% for x in [a,b]; 
     "item: $x\n";
   end;
%]
-- expect -- 
item: alpha
item: bravo

-- test for x in [a,b] as side-effect --
[% "item: $x\n" for x in [a,b] %]
-- expect -- 
item: alpha
item: bravo

-- test for [a b] --
%% for [a, b]; 'item: '; item; '  '; end; 'done'
-- expect -- 
item: alpha  item: bravo  done

-- test list generator --
%% [item * 3 for [1, 3, 5]].join
-- expect --
3 9 15

-- test list generator with guard --
[%
    [   for [1, 2, 3, 4, 5, 6];
            if item < 5;
                item * 2;
            end;
        end 
    ].join

%]
-- expect --
2 4 6 8

-- test list generator with braces --
-- block --
[%
    [   for [1, 2, 3, 4, 5, 6] {
            if item < 5 {
                item * 2
            }
        }
    ].join

%]
-- expect --
2 4 6 8

-- test list generator with single block expressions --
[% 
    [   for [1, 2, 3, 4, 5, 6] 
            if item < 5
                item * 2
    ].join

%]
-- expect --
2 4 6 8

-- test list generator with guard in side-effect --
[%
    [   item * 3 
            if item < 5
                for [1, 2, 3, 4, 5, 6]
    ].join

%]
-- expect --
3 6 9 12

-- test undefined value --
%% for failage yak
-- error --
TT3 data error at line 1 of "undefined value" test:
    Error: Undefined value: failage
   Source: %% for failage yak
                  ^ here

-- test undefined value is ok with else --
%% for failage yak else soz
-- expect --
I'm sorry Dave, I'm afraid I can't do that.

-- test undefined dotted value --
%% for wiz.waz yak
-- error --
TT3 data error at line 1 of "undefined dotted value" test:
    Error: Undefined value: wiz.waz
   Source: %% for wiz.waz yak
                     ^ here

-- test for else --
%% l = [ ]; for l; item; else; 'no items'; end
-- expect --
no items

-- test if/for/else true and empty --
[% 
    list = [ ]; 
    if a
        for list
            item
        else
            'no items'
    else
        'no alpha'
%]
-- expect --
no items

-- test if/for/else false and empty --
[%
    list = [ ]; 
    if not a
        for list
            item
        else
            'no items'
    else
        'no alpha'
%]
-- expect --
no alpha

-- test if/for/else true and full --
[%  '<'
    list = [ b c ]; 
    if a
        for list
            ' * ' ~ item
        else
            'no items'
    else
        'no alpha'
    '>'
%]
-- expect --
< * bravo * charlie>

-- test for ... end#for --
%% for x in 1 to 3
x: [% x %]
%% end#for
-- expect --
x: 1
x: 2
x: 3

-- test for#bar ... end#bar --
%% for#bar x in 1 to 3
x: [% x %]
%% end#bar
-- expect --
x: 1
x: 2
x: 3

-- test for#bar ... end#for --
%% for#bar x in 1 to 3
x: [% x %]
%% end#for
-- expect --
x: 1
x: 2
x: 3

-- test iterator methods --
%% for x in 11 to 15
[% loop.count %]: [% x %]
%% end
-- expect --
1: 11
2: 12
3: 13
4: 14
5: 15


-- test mismatched fragment error --
%% for x in 1 to 3
x: [% x %]
%% end#if
-- error --
TT3 syntax error at line 3 of "mismatched fragment error" test:
    Error: Mismatched fragment at end of 'for' block: end#if
   Source: %% end#if
                  ^ here

-- test illegal follow declaration --
# TODO: create a custom command in t/lib which is deliberately broken
-- skip this requires the 'For' command to be broken --
%% for x y fill z;
-- expect --
<ERROR:'fill' cannot follow 'for'>

