#============================================================= -*-perl-*-
#
# t/modules/iterator.t
#
# Test the Template::TT3::Iterator module.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib';
    
use Template::TT3::Test 
    debug => 'Template::TT3::Iterator',
    args  => \@ARGV,
    tests => 60;

use Template::TT3::Iterator;
use constant ITER => 'Template::TT3::Iterator';

ok( 1, 'loaded Template::TT3::Iterator' );


#-----------------------------------------------------------------------
# test the various iterator methods: one(), prev(), item(), first(), etc.
#-----------------------------------------------------------------------

my $iter = ITER->new([10, 20, 30, 40, 50]);
ok(   $iter,            'created iterator' );
is(   $iter->one,   10, 'got first item' );
ok( ! $iter->prev,      'no previous first item' );
is(   $iter->item,  10, 'item is 10' );
is(   $iter->next,  20, 'next item is 20' );
ok(   $iter->first,     'on first item' );
is(   $iter->index,  0, 'index is 0' );
is(   $iter->count,  1, 'count is 1' );
ok( ! $iter->last,      'not on the last item' );
ok( ! $iter->done,      'iterator has only just begun' );

is(   $iter->one,   20, 'got second item' );
is(   $iter->prev,  10, 'previous item is 10' );
is(   $iter->item,  20, 'item is 20' );
is(   $iter->next,  30, 'next item is 30' );
ok( ! $iter->first,     'no longer on first item' );
is(   $iter->index,  1, 'index is 1' );
is(   $iter->count,  2, 'count is 2' );
ok( ! $iter->last,      'nope, not on the last item' );
ok( ! $iter->done,      'iterator is going string' );

is(   $iter->one,   30, 'got third item' );
is(   $iter->prev,  20, 'previous item is 20' );
is(   $iter->item,  30, 'item is 30' );
is(   $iter->next,  40, 'next item is 40' );
ok( ! $iter->first,     'not on first item' );
is(   $iter->index,  2, 'index is 2' );
is(   $iter->count,  3, 'count is 3' );
ok( ! $iter->last,      'still not on the last item' );
ok( ! $iter->done,      'iterator is still going strong' );

is(   $iter->one,   40, 'got fourth item' );
is(   $iter->prev,  30, 'previous item is 30' );
is(   $iter->item,  40, 'item is 40' );
is(   $iter->next,  50, 'next item is 50' );
ok( ! $iter->first,     'still not on first item' );
is(   $iter->index,  3, 'index is 3' );
is(   $iter->count,  4, 'count is 4' );
ok( ! $iter->last,      'really not on the last item' );
ok( ! $iter->done,      'iterator has still got more to go' );

is(   $iter->one,   50, 'got fifth item' );
is(   $iter->prev,  40, 'previous item is 40' );
is(   $iter->item,  50, 'item is 50' );
ok( ! $iter->next,      'no next item' );
ok( ! $iter->first,     "of course it's not on first item" );
is(   $iter->index,  4, 'index is 4' );
is(   $iter->count,  5, 'count is 5' );
ok(   $iter->last,      'now we are on the last item' );
ok(   $iter->done,      'iterator has got nowhere left to go' );


my ($r, $done) = $iter->one;
ok( ! $r, 'no result after last item' );
ok( $done, 'status done after last item' );
ok( $iter->done, 'iterator done after last item' );


#-----------------------------------------------------------------------
# all() returns the rest of the items
#-----------------------------------------------------------------------

$iter->reset;
ok( ! $iter->done, 'iterator is no longer done' );
my $list = $iter->all;
is( scalar(@$list), 5, 'got 5 items from all' );
ok( $iter->done, 'iterator done after fetch all' );

$iter->reset;
is( $iter->one, 10, 'another one' );
is( $iter->one, 20, 'another two' );
$list = $iter->all;
is( scalar(@$list), 3, 'got 5 remaining items from all' );

ok( $iter->done, 'iterator done after fetch all for remaining items' );


#-----------------------------------------------------------------------
# test an empty iterator
#-----------------------------------------------------------------------

$iter = ITER->new([]);
ok( $iter->done, 'empty iterator is already done' );
($r, $done) = $iter->one;
ok( ! $r, 'no result from empty iterator' );
ok( $done, 'done status from empty iterator' );


