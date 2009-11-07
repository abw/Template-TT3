#============================================================= -*-perl-*-
#
# t/type/list.t
#
# Test the Template::TT3::Type::List.pm module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug  => 'Template::TT3::Type::List',
    args   => \@ARGV,
    tests  => 344;

use Template::TT3::Type::List qw(List LIST);

local $" = ', ';

my ($data, $list, $copy, $sub);

is( LIST->type, 'List', 'List type' );
is( ref LIST->methods, 'HASH', 'List methods' );

is( List->type(), 'List', 'List type' );
is( ref List->methods(), 'HASH', 'List methods' );


#------------------------------------------------------------------------
# new() class method
#------------------------------------------------------------------------

# list of params
$list = List->new( 10, 20, 30 );
ok( $list, 'created a list from params' );
is( scalar @$list, 3, 'three items in list' );
is( $list->[0], 10, 'first item is 10' );
is( $list->[1], 20, 'second item is 20' );
is( $list->[2], 30, 'third item is 30' );

# list reference
$data = [ 100, 200, 300 ];
$list = List->new($data);
is( scalar @$list, 3, 'three items in list ref' );
ok( $list, 'created a hash from a list ref' );
is( $list->[0], 100, 'first item is 100' );
is( $list->[1], 200, 'second item is 200' );
is( $list->[2], 300, 'third item is 300' );

# should be a wrapper around original data 
push(@$data, 400);
is( $list->[3], 400, 'fourth list item is 400' );

# create List by copying another List
$copy = List->new($list);
is( scalar @$list, 4, 'four items in list copy' );
ok( $copy, 'created copy of list' );
is( $copy->[0], 100, 'first copy is 100' );
is( $copy->[1], 200, 'second copy is 200' );
is( $copy->[2], 300, 'third copy is 300' );
is( $copy->[3], 400, 'fourth copy is 400' );


#------------------------------------------------------------------------
# new() object method
#------------------------------------------------------------------------

# list of named params
$copy = $list->new( 3.14, 2.718 );
ok( $copy, 'object new with params list' );
is( $copy->[0], 3.14, 'one is 3.14' );
is( $copy->[1], 2.718, 'two is 2.718' );
is( scalar @$copy, 2, 'two items in copy' );

# list ref
$copy = $list->new([ 3.14, 2.718 ]);
ok( $copy, 'object new with params list ref' );
is( $copy->[0], 3.14, 'one ref is 3.14' );
is( $copy->[1], 2.718, 'two ref is 2.718' );
is( scalar @$copy, 2, 'two items in copy ref ' );

# List ref
my $copy2 = $list->new($copy);
ok( $copy2, 'object new with object' );
is( $copy->[0], 3.14, 'one copy is 3.14' );
is( $copy->[1], 2.718, 'two copy is 2.718' );
is( scalar @$copy, 2, 'two items in object copy ' );


#------------------------------------------------------------------------
# clone() method
#------------------------------------------------------------------------

$list = List->new( 3.14, 2.718 );
$copy = $list->clone();
ok( $copy, 'cloned new object' );
is( scalar @$copy, 2, 'two items in clone ' );
is( $copy->[0], 3.14, 'clone one is 3.14' );
is( $copy->[1], 2.718, 'clone two is 2.718' );

push(@$list, 1.618);
is( scalar @$copy, 2, 'still two items in clone ' );

# extra argument to clone() as list
$list = List->new(3.14, 2.718);
$copy = $list->clone(1.618);
ok( $copy, 'cloned new object with extra' );
is( scalar @$copy, 3, 'three items in clone ' );
is( $copy->[0], 3.14, 'clone one is 3.14 again' );
is( $copy->[1], 2.718, 'clone two is 2.718 again' );
is( $copy->[2], 1.618, 'clone three is 1.618' );

# extra argument to clone() as list ref
$copy = $list->clone([1.618, 0.577]);
ok( $copy, 'cloned new object with list ref' );
is( scalar @$copy, 4, 'four items in clone ' );
is( $copy->[0], 3.14, 'clone one is 3.14 once again' );
is( $copy->[1], 2.718, 'clone two is 2.718 once again' );
is( $copy->[2], 1.618, 'clone three is 1.618 once again' );
is( $copy->[3], 0.577, 'clone four is 0.577' );



#------------------------------------------------------------------------
# copy() method
#------------------------------------------------------------------------

$list = List->new( 3.14, 2.718 );
$copy = $list->copy();
ok( $copy, 'copied new object' );
is( scalar @$copy, 2, 'two items in copy ' );
is( $copy->[0], 3.14, 'copy one is 3.14' );
is( $copy->[1], 2.718, 'copy two is 2.718' );

push(@$list, 1.618);
is( scalar @$copy, 2, 'still two items in copy ' );

# extra argument to copy() as list
$list = List->new(3.14, 2.718);
$copy = $list->copy(1.618);
ok( $copy, 'copied new object with extra' );
is( scalar @$copy, 3, 'three items in copy ' );
is( $copy->[0], 3.14, 'copy one is 3.14 again' );
is( $copy->[1], 2.718, 'copy two is 2.718 again' );
is( $copy->[2], 1.618, 'copy three is 1.618' );

# extra argument to copy() as list ref
$copy = $list->copy([1.618, 0.577]);
ok( $copy, 'copied new object with list ref' );
is( scalar @$copy, 4, 'four items in copy ' );
is( $copy->[0], 3.14, 'copy one is 3.14 once again' );
is( $copy->[1], 2.718, 'copy two is 2.718 once again' );
is( $copy->[2], 1.618, 'copy three is 1.618 once again' );
is( $copy->[3], 0.577, 'copy four is 0.577' );


#------------------------------------------------------------------------
# ref() and type() methods
#------------------------------------------------------------------------

$data = [ 10, 20, 30 ];

is( $list->ref(), LIST, 'object ref List' );
is( $list->can('ref')->($data), 'ARRAY', 'data ref ARRAY' );

is( $list->type(), 'List', 'object type List' );
is( $list->can('type')->($data), 'List', 'data type List' );


#------------------------------------------------------------------------
# hash() method
#------------------------------------------------------------------------

$list = List->new( pi => 3.14, e => 2.718 );
my $hash = $list->hash();
is( $hash->{ pi }, 3.14, 'list hash pi is 3.14' );
is( $hash->{ e  }, 2.718, 'list hash e is 2.718' );


#------------------------------------------------------------------------
# list() method
#------------------------------------------------------------------------

is( $list, $list->list->list(), 'list is a null op' );


#------------------------------------------------------------------------
# text() method
#------------------------------------------------------------------------

is( $list->text(), 'pi, 3.14, e, 2.718',
    'default list text' );

is( $list->text(','),  'pi,3.14,e,2.718',
    'list text with delim' );


#------------------------------------------------------------------------
# item() method
#------------------------------------------------------------------------

$list = List->new(1.618, 2.718, 3.14);
is( $list->item(0), 1.618, 'list item 0 is phi' );
is( $list->item(1), 2.718, 'list item 1 is e' );
is( $list->item(2), 3.14 , 'list item 2 is pi' );
ok( ! defined $list->item(3), 'no item 3' );


#------------------------------------------------------------------------
# first() method
#------------------------------------------------------------------------

is( $list->first(), 1.618, 'first list item is phi' );
$copy = $list->first(1);
is( scalar @$copy, 1, 'one first item' );
is( $copy->[0], 1.618, 'first item 1 is phi' );

$copy = $list->first(2);
is( scalar @$copy, 2, 'two first items' );
is( $copy->[0], 1.618, 'first of two items is phi' );
is( $copy->[1], 2.718, 'second of two items is e' );

$copy = $list->first(19);
is( scalar @$copy, 3, 'only three items available from first' );


#------------------------------------------------------------------------
# last() method
#------------------------------------------------------------------------

is( $list->last(), 3.14, 'last list item is pi' );
$copy = $list->last(1);
is( scalar @$copy, 1, 'one last item' );
is( $copy->[0], 3.14, 'last item 1 is pi' );

$copy = $list->last(2);
is( scalar @$copy, 2, 'two last items' );
is( $copy->[0], 2.718, 'first of last two items is e' );
is( $copy->[1], 3.14, 'second of last two items is pi' );

$copy = $list->last(19);
is( scalar @$copy, 3, 'only three items available from last' );


#------------------------------------------------------------------------
# max() and size() methods
#------------------------------------------------------------------------

is( $list->size(), 3, 'list size is 3' );
is( $list->max(), 2, 'list max is 2' );


#------------------------------------------------------------------------
# grep()
#------------------------------------------------------------------------

my $grep = $list->grep('8');
is( scalar @$grep, 2, 'two items in grep' );
is( $grep->[0], 1.618, 'grep phi first' );
is( $grep->[1], 2.718, 'grep e second' );


#------------------------------------------------------------------------
# sort() and nsort()
#------------------------------------------------------------------------

$list = List->new(1, 10, 3, 5, 11);
my $sort = $list->sort();
is( join(', ', @$sort), '1, 10, 11, 3, 5', 'alpha list sort' );

$sort = $list->nsort();
is( join(', ', @$sort), '1, 3, 5, 10, 11', 'number list sort' );

$list = List->new({n=>1}, {n=>10}, {n=>3}, {n=>5}, {n=>11});
$sort = $list->sort('n');
is( join(', ', map { $_->{n} } @$sort), '1, 10, 11, 3, 5', 
    'alpha list sort n' );

$sort = $list->nsort('n');
is( join(', ', map { $_->{n} } @$sort), '1, 3, 5, 10, 11', 
    'number list sort n' );


#------------------------------------------------------------------------
# unique()
#------------------------------------------------------------------------

$list = List->new(10, 20, 10, 30, 40, 10, 50, 30, 10);
my $unique = $list->unique();
is( join(', ', @$unique), '10, 20, 30, 40, 50', 'got list unique' );


#------------------------------------------------------------------------
# reverse()
#------------------------------------------------------------------------

$list = List->new(10, 20, 30, 40, 50);
my $reverse = $list->reverse();
is( join(', ', @$reverse), '50, 40, 30, 20, 10', 'reversed items' );
is( join(', ', @$list), '10, 20, 30, 40, 50', 'original list unchanged' );


#------------------------------------------------------------------------
# slice()
#------------------------------------------------------------------------

$list = List->new(10, 20, 30, 40, 50);
my $slice = $list->slice();
is( join(', ', @$slice), '10, 20, 30, 40, 50', 'full slice items' );
is( join(', ', @$list), '10, 20, 30, 40, 50', 'original list unsliced' );

$slice = $list->slice(5);
is( scalar @$slice, 0, 'no slice' );

$slice = $list->slice(4);
is( scalar @$slice, 1, 'one slice' );
is( $slice->[0], 50, 'slice one is 50' );

$slice = $list->slice(4, 20);
is( scalar @$slice, 1, 'still one slice' );
is( $slice->[0], 50, 'slice one is still 50' );

$slice = $list->slice(3, 4);
is( scalar @$slice, 2, 'two slices' );
is( $slice->[0], 40, 'slice one is now 40' );
is( $slice->[1], 50, 'slice two is now 50' );



#------------------------------------------------------------------------
# push() and pop()
#------------------------------------------------------------------------

$list = List->new(10, 20, 30);
is( $list->push(40), '', 'pushed one item' );
is( $list->text(), '10, 20, 30, 40', 'pushed item 40' );
is( $list->push(50, 60), '', 'pushed two items' );
is( $list->text(), '10, 20, 30, 40, 50, 60', 'pushed items 50 and 60' );

is( $list->pop(), 60, 'popped 60 off' );
is( $list->text(), '10, 20, 30, 40, 50', 'popped off 60' );
my $pop = $list->pop(2);
is( ref $pop, 'ARRAY', 'popped off two items' );
is( $pop->[0], 40, 'popped off 40' );
is( $pop->[1], 50, 'popped off 50' );
is( $list->text(), '10, 20, 30', 'popped off items 40 and 50' );

$pop = $list->pop(100);
is( $list->text(), '', 'no text' );
is( scalar @$pop, 3, 'three items popped off' );


#------------------------------------------------------------------------
# shift() and unshift()
#------------------------------------------------------------------------

$list = List->new(40, 50, 60);
is( $list->unshift(30), 4, 'unshifted one item' );
is( $list->text(), '30, 40, 50, 60', 'unshifted item 30' );
is( $list->unshift(10, 20), 6, 'unshifted two items' );
is( $list->text(), '10, 20, 30, 40, 50, 60', 'unshifted items 10 and 20' );

is( $list->shift(), 10, 'shifted 10 off' );
is( $list->text(), '20, 30, 40, 50, 60', 'shifted 10' );
my $shift = $list->shift(2);
is( ref $shift, 'ARRAY', 'shifted two items' );
is( $shift->[0], 20, 'shifted 20' );
is( $shift->[1], 30, 'shifted 30' );
is( $list->text(), '40, 50, 60', 'shifted items 20 and 30' );

$shift = $list->shift(100);
is( $list->text(), '', 'no text' );
is( scalar @$shift, 3, 'three remaining items shifted' );


#------------------------------------------------------------------------
# splice() method
#------------------------------------------------------------------------


$list = List->new(qw( foo bar baz ));

$copy = $list->splice(3, 0, 'bam');
is( ref $copy, 'ARRAY', 'splice returned list' );
is( scalar @$copy, 0, 'empty list returned' );
is( scalar @$list, 4, 'list has 4 items' );
is( $list->[3], 'bam', 'last item is bam' );

$copy = $list->splice(3, 1, 'ping', 'pong');
is( ref $copy, 'ARRAY', 'splice returned list' );
is( scalar @$copy, 1, '1 item returned' );
is( $copy->[0], 'bam', 'list item is bam' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[3], 'ping', 'item 3 is ping' );
is( $list->[4], 'pong', 'item 4 is pong' );

$copy = $list->splice(3, 2, [ 'bing', 'bang' ]);
is( ref $copy, 'ARRAY', 'splice returned list' );
is( scalar @$copy, 2, '2 items returned' );
is( $copy->[0], 'ping', 'list item 0 is ping' );
is( $copy->[1], 'pong', 'list item 1 is pong' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[3], 'bing', 'item 3 is bing' );
is( $list->[4], 'bang', 'item 4 is bang' );

$copy = $list->splice(3);
is( ref $copy, 'ARRAY', 'splice returned list' );
is( scalar @$copy, 2, '2 items returned' );
is( $copy->[0], 'bing', 'item 0 is bing' );
is( $copy->[1], 'bang', 'item 1 is bang' );
is( scalar @$list, 3, '3 items left' );
is( $list->[0], 'foo', 'item 0 is foo' );
is( $list->[2], 'baz', 'item 2 is baz' );

$copy = $list->splice();
is( ref $copy, 'ARRAY', 'splice returned list' );
is( scalar @$copy, 3, '3 items returned' );
is( $copy->[0], 'foo', 'item 0 is foo' );
is( $copy->[2], 'baz', 'item 2 is baz' );
is( scalar @$list, 0, '0 items left' );


#------------------------------------------------------------------------
# merge() method
#------------------------------------------------------------------------

$list = List->new([ qw( foo bar baz ) ]);
$copy = $list->merge( );
is( $list, $copy, 'merge returned same list' );
is( scalar @$list, 3, 'list has 3 items' );

$copy = $list->merge( 'ping', 'pong' );
is( $list, $copy, 'merge returned same list' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[3], 'ping', 'item 3 is ping' );
is( $list->[4], 'pong', 'item 4 is pong' );

$copy = $list->merge( [ 'sing', 'song' ], 'sung' );
is( $list, $copy, 'merge returned same list' );
is( scalar @$list, 8, 'list has 8 items' );
is( $list->[5], 'sing', 'item 5 is sing' );
is( $list->[6], 'song', 'item 6 is song' );
is( $list->[7], 'sung', 'item 7 is sung' );




#========================================================================
# The following test various methods by calling them as plain subroutines,
# passing a list reference as the first argument to masquerade as a List
# object.  Many of them duplicates the above tests, but it doesn't hurt
# to have too many.  In some cases the above object tests are less
# thorough than those below, so we do get some extra coverage from it.
#========================================================================


# subroutine to fetch and call list virtual method for us
sub lvm {
    my ($vmeth, @args) = @_;
    my $method = List->can($vmeth) || return undef;    
#    my $method = List->vmethod($vmeth) || return undef;    
    &$method(@args);
}

ok( ! defined lvm( nonsuch => 'hello' ), 'undefined handler' );

$list = [ qw( foo bar baz ) ];
my ($list2, $hash2);


#------------------------------------------------------------------------
# ref, type
#------------------------------------------------------------------------

is( lvm( ref => $list), 'ARRAY', 'ARRAY ref' );
is( lvm( type => $list), 'List', 'List type' );


#------------------------------------------------------------------------
# text, item, list, hash, copy
#------------------------------------------------------------------------

is( lvm( text => $list), 'foo, bar, baz', 'text conversion' );
is( lvm( item => $list), 'foo', 'item foo' );
is( lvm( item => $list, 0), 'foo', 'item 0 foo' );
is( lvm( item => $list, 1), 'bar', 'item 1 bar' );
$list2 = lvm( list => $list);
is( ref $list2, 'ARRAY', 'list no-op' );
is( $list, $list2, 'same list' );
is( $list2->[0], 'foo', 'foo is first' );

push(@$list, 'bam');
$hash2 = lvm( hash => $list );
is( ref $hash2, 'HASH', 'hash conversion' );
is( $hash2->{foo}, 'bar', 'foo is bar' );
is( $hash2->{baz}, 'bam', 'baz is bam' );
$list2 = lvm( copy => $list);
is( ref $list2, 'ARRAY', 'list copy' );
ok( $list ne $list2, 'different list' );
is( $list2->[0], 'foo', 'foo is still first' );


#------------------------------------------------------------------------
# pop, push, shift, unshift
#------------------------------------------------------------------------

is( lvm( pop => $list), 'bam', 'first pop' );
is( ref lvm( pop => $list, 2), 'ARRAY', 'second pop two' );
is( scalar @$list, 1, 'one item left');
is( $list->[0], 'foo', 'item is foo');

is( lvm( push => $list, 'bar' ), '', 'single push' );
is( scalar @$list, 2, 'two items now');
is( $list->[1], 'bar', 'second item is bar' );
is( lvm( push => $list, 'baz' ), '', 'another push' );
is( scalar @$list, 3, 'three items now');
is( $list->[2], 'baz', 'third item is baz' );

is( lvm( push => $list, 'ping', 'pong' ), '', 'yet another push' );
is( scalar @$list, 5, 'five items now');
is( $list->[3], 'ping', 'ping' );
is( $list->[4], 'pong', 'pong' );

is( lvm( pop => $list ), 'pong', 'pop pong' );
is( lvm( pop => $list ), 'ping', 'pop ping' );

is( lvm( shift => $list), 'foo', 'first shift' );
is( lvm( shift => $list), 'bar', 'second shift' );
is( scalar @$list, 1, 'one item left');
is( $list->[0], 'baz', 'item is baz');

is( lvm( unshift => $list, 'bar' ), 2, 'single unshift' );
is( scalar @$list, 2, 'two items now');
is( $list->[0], 'bar', 'first item is bar' );
is( lvm( unshift => $list, 'foo' ), 3, 'another unshift' );
is( scalar @$list, 3, 'three items now');
is( $list->[0], 'foo', 'first item is foo' );
is( $list->[1], 'bar', 'second item is bar');

is( lvm( unshift => $list, 'ping', 'pong' ), 5, 'yet another unshift' );
is( scalar @$list, 5, 'five items now');
is( $list->[0], 'ping', 'ping' );
is( $list->[1], 'pong', 'pong' );


#------------------------------------------------------------------------
# splice
#------------------------------------------------------------------------

$list = [ qw( foo bar baz ) ];

$list2 = lvm( splice => $list, 3, 0, 'bam' );
is( ref $list2, 'ARRAY', 'splice returned list' );
is( scalar @$list2, 0, 'empty list returned' );
is( scalar @$list, 4, 'list has 4 items' );
is( $list->[3], 'bam', 'last item is bam' );

$list2 = lvm( splice => $list, 3, 1, 'ping', 'pong' );
is( ref $list2, 'ARRAY', 'splice returned list' );
is( scalar @$list2, 1, '1 item returned' );
is( $list2->[0], 'bam', 'list item is bam' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[3], 'ping', 'item 3 is ping' );
is( $list->[4], 'pong', 'item 4 is pong' );

$list2 = lvm( splice => $list, 3, 2, [ 'bing', 'bang' ]);
is( ref $list2, 'ARRAY', 'splice returned list' );
is( scalar @$list2, 2, '2 items returned' );
is( $list2->[0], 'ping', 'list item 0 is ping' );
is( $list2->[1], 'pong', 'list item 1 is pong' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[3], 'bing', 'item 3 is bing' );
is( $list->[4], 'bang', 'item 4 is bang' );

$list2 = lvm( splice => $list, 3);
is( ref $list2, 'ARRAY', 'splice returned list' );
is( scalar @$list2, 2, '2 items returned' );
is( $list2->[0], 'bing', 'item 0 is bing' );
is( $list2->[1], 'bang', 'item 1 is bang' );
is( scalar @$list, 3, '3 items left' );
is( $list->[0], 'foo', 'item 0 is foo' );
is( $list->[2], 'baz', 'item 2 is baz' );

$list2 = lvm( splice => $list );
is( ref $list2, 'ARRAY', 'splice returned list' );
is( scalar @$list2, 3, '3 items returned' );
is( $list2->[0], 'foo', 'item 0 is foo' );
is( $list2->[2], 'baz', 'item 2 is baz' );
is( scalar @$list, 0, '0 items left' );


#------------------------------------------------------------------------
# merge
#------------------------------------------------------------------------

$list  = [ qw( foo bar baz ) ];
$list2 = lvm( merge => $list );
is( $list, $list2, 'merge returned same list' );
is( scalar @$list, 3, 'list has 3 items' );

$list2 = lvm( merge => $list, 'ping', 'pong' );
is( $list, $list2, 'merge returned same list' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[3], 'ping', 'item 3 is ping' );
is( $list->[4], 'pong', 'item 4 is pong' );

$list2 = lvm( merge => $list, [ 'sing', 'song' ], 'sung' );
is( $list, $list2, 'merge returned same list' );
is( scalar @$list, 8, 'list has 8 items' );
is( $list->[5], 'sing', 'item 5 is sing' );
is( $list->[6], 'song', 'item 6 is song' );
is( $list->[7], 'sung', 'item 7 is sung' );


#------------------------------------------------------------------------
# max, size, first, last
#------------------------------------------------------------------------

$list = [ qw( foo bar baz ) ];

is( lvm( max => $list ), '2', 'max is 2' );
is( lvm( size => $list ), '3', 'size is 3' );
is( lvm( first => $list ), 'foo', 'foo is first' );
is( lvm( last => $list ), 'baz', 'baz is last' );

$list2 = lvm( first => $list, 1 );
is( ref $list2, 'ARRAY', 'first returned array' );
is( scalar @$list2, 1, '1 item list returned' );
is( $list2->[0], 'foo', 'foo returned' );
is( scalar @$list, 3, '3 items left' );

$list2 = lvm( first => $list, 2 );
is( ref $list2, 'ARRAY', 'first returned array' );
is( scalar @$list2, 2, '2 item list returned' );
is( $list2->[0], 'foo', 'item 0 is foo' );
is( $list2->[1], 'bar', 'item 1 is bar' );
is( scalar @$list, 3, '3 items left' );

$list2 = lvm( last => $list, 1 );
is( ref $list2, 'ARRAY', 'last returned array' );
is( scalar @$list2, 1, '1 item list returned' );
is( $list2->[0], 'baz', 'baz returned' );
is( scalar @$list, 3, '3 items left' );

$list2 = lvm( last => $list, 2 );
is( ref $list2, 'ARRAY', 'last returned array' );
is( scalar @$list2, 2, '2 item list returned' );
is( $list2->[0], 'bar', 'item 0 is bar' );
is( $list2->[1], 'baz', 'item 1 is baz' );
is( scalar @$list, 3, '3 items left' );


#------------------------------------------------------------------------
# reverse, grep, join
#------------------------------------------------------------------------

$list = [ qw( foo bar baz ping pong ) ];

$list2 = lvm( reverse => $list );
ok( $list2, 'reverse' );
is( scalar @$list2, 5, '5 items' );
is( $list2->[0], 'pong', 'pong is first' );
is( $list2->[-1], 'foo', 'foo is last' );

$list2 = lvm( grep => $list, 'p' );
ok( $list2, 'grep' );
is( scalar @$list2, 2, '2 items' );
is( $list2->[0], 'ping', 'ping' );
is( $list2->[1], 'pong', 'pong' );

is( lvm( join => $list ), 'foo bar baz ping pong', 'join 1' );
is( lvm( join => $list, ', ' ), 'foo, bar, baz, ping, pong', 'join 2' );


#------------------------------------------------------------------------
# slice
#------------------------------------------------------------------------

$list2 = lvm( slice => $list );
is( ref $list2, 'ARRAY', 'slice returned an array' );
is( scalar @$list2, 5, '5 items returned' );
is( $list2->[0], 'foo', 'foo is first' );
is( $list2->[-1], 'pong', 'pong is last' );
is( scalar @$list, 5, 'original list untouched' );

$list2 = lvm( slice => $list, 3 );
is( ref $list2, 'ARRAY', 'slice returned an array' );
is( scalar @$list2, 2, '2 items returned' );
is( $list2->[0], 'ping', 'ping is first' );
is( $list2->[1], 'pong', 'pong is second' );

$list2 = lvm( slice => $list, 3, 4 );
is( ref $list2, 'ARRAY', 'slice returned an array' );
is( scalar @$list2, 2, '2 items returned' );
is( $list2->[0], 'ping', 'ping is first' );
is( $list2->[1], 'pong', 'pong is second' );


#------------------------------------------------------------------------
# unique
#------------------------------------------------------------------------

$list = [ qw( foo bar foo bing bang bang baz ) ];

$list2 = lvm( unique => $list );
is( ref $list2, 'ARRAY', 'slice returned an array' );
is( scalar @$list2, 5, '5 items returned' );
is( $list2->[0], 'foo', 'unique 0 is foo' );
is( $list2->[1], 'bar', 'unique 1 is bar' );
is( $list2->[2], 'bing', 'unique 2 is bing' );
is( $list2->[3], 'bang', 'unique 3 is bang' );
is( $list2->[4], 'baz', 'unique 4 is baz' );
is( scalar @$list, 7, 'original list untouched' );



#------------------------------------------------------------------------
# sort, nsort
#------------------------------------------------------------------------

$list = [ qw( ping pong foo baz bar ) ];
$list2 = lvm( sort => $list );
ok( $list2, 'sort' );
is( lvm( join => $list2 ), 'bar baz foo ping pong', 'sorted' );

my $numbers = [ 0, 1, 10, 11, 2, 0.2, 22, 30 ];
$list2 = lvm( nsort => $numbers );
ok( $list2, 'nsort' );
is( lvm( join => $list2 ), '0 0.2 1 2 10 11 22 30', 'nsorted' );

# define a simple object to test sort vmethod calling object method

package My::Object;

sub new { 
    my ($class, $name) = @_;
    bless {
        _NAME => $name,
    }, $class;
}

sub name { 
    my $self = shift;
    return $self->{ _NAME };
}

package main;

# same for hash items

my $people = [ 
    { id => 'tom',   name => 'Tom' },
    { id => 'dick',  name => 'Richard' },
    { id => 'larry', name => 'Larry' },
];

my $sorted = lvm( sort => $people, 'id' );
ok( $sorted, 'list sorted' );
is( scalar @$sorted, 3, '3 items' );
is( $sorted->[0]->{ name }, 'Richard', 'dick first' );
is( $sorted->[1]->{ name }, 'Larry', 'larry second' );
is( $sorted->[2]->{ name }, 'Tom', 'tom last' );

$sorted = lvm( sort => $people, 'name' );
ok( $sorted, 'list sorted' );
is( scalar @$sorted, 3, '3 items again' );
is( $sorted->[0]->{ name }, 'Larry', 'larry first' );
is( $sorted->[1]->{ name }, 'Richard', 'dick next' );
is( $sorted->[2]->{ name }, 'Tom', 'tom last' );

my $names = [ 
    map { My::Object->new($_) }
    qw( Tom Dick Larry ) 
];

$sorted = lvm( sort => $names, 'name' );
ok( $sorted, 'list sorted' );
is( scalar @$sorted, 3, '3 items yet again' );
is( $sorted->[0]->name(), 'Dick', 'dick first again' );
is( $sorted->[1]->name(), 'Larry', 'larry next again' );
is( $sorted->[2]->name(), 'Tom', 'tom last again' );


my $number_objs = [ 
    map { My::Object->new($_) }
    qw( 1 02 10 12 021 ) 
];

$sorted = lvm( nsort => $number_objs, 'name' );
ok( $sorted, 'list sorted' );
is( scalar @$sorted, 5, '5 items' );
is( $sorted->[0]->name(), 1, 'sort 0 is 1' );
is( $sorted->[1]->name(), '02', 'sort 1 is 2' );
is( $sorted->[2]->name(), 10, 'sort 2 is 10' );
is( $sorted->[3]->name(), 12, 'sort 3 is 12' );
is( $sorted->[4]->name(), '021', 'sort 4 is 21' );



