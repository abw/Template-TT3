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
    tests   => 16,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::Element::Command::For;

my $vars = callsign;
$vars->{ foo } = 10;
$vars->{ bar } = 20;
$vars->{ wiz } = { waz => undef };

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
TT3 undefined data error at line 1 of "undefined value" test:
    Error: Undefined value returned by expression: failage
   Source: %% for failage yak
                  ^ here


-- test undefined dotted value --
%% for wiz.waz yak
-- error --
TT3 undefined data error at line 1 of "undefined dotted value" test:
    Error: Undefined value returned by expression: wiz.waz
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

-- test illegal follow declaration --
# TODO: create a custom command in t/lib which is deliberately broken
-- skip this requires the 'For' command to be broken --
%% for x y fill z;
-- expect --
<ERROR:'fill' cannot follow 'for'>


