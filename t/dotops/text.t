#============================================================= -*-perl-*-
#
# t/dotops/text.t
#
# Test script for text dotops.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

#use Badger::Debug modules => 'Template::TT3::Variables';
use Template::TT3::Test 
    tests   => 24,
    debug   => 'Template::TT3::Template Template::TT3::Variables',
    args    => \@ARGV,
    import  => 'test_expect callsign';

my $vars = {
    foo => 'this is foo',
    bar => 'and this is bar',
    %{ callsign() },
};

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test foo.length --
%% foo.length
-- expect --
11

-- test foo.upper --
%% foo.upper
-- expect --
THIS IS FOO

-- test foo.split.join --
%% foo.split.join('/')
-- expect --
this/is/foo

-- test foo.mushroom --
%% foo.mushroom
-- error --
Invalid text method: foo.mushroom

-- test 'snake'.length --
%% 'snake'.length
-- expect --
5

-- test 'snake'.mushroom --
%% 'snake'.mushroom
-- error --
Invalid text method: 'snake'.mushroom

-- test text.trim --
%% '  hello  '.trim
-- expect --
hello


#-----------------------------------------------------------------------
# is
#-----------------------------------------------------------------------

-- test text.is --
%% a.is('alpha') ? a : b
-- expect --
alpha

-- test text.is not --
%% a.is('bravo') ? a : b
-- expect --
bravo

-- test text.in(item) --
%% a.in('alpha') ? c : d
-- expect --
charlie

-- test text.in(item) not --
%% a.in('bravo') ? c : d
-- expect --
delta

-- test text.in(item,item,item) --
%% a.in(a,b,c) ? e : f
-- expect --
echo

-- test text.in(item,item,item) jiggled --
%% a.in(b,c,a) ? f : g
-- expect --
foxtrot

-- test text.in(item,item,item) not --
%% a.in(b,c,d) ? f : g
-- expect --
golf

-- test text.in(list)  --
%% a.in([b,c,a]) ? h : i
-- expect --
hotel

-- test text.in(list) not --
%% a.in([b,c,d]) ? h : i
-- expect --
india

-- test text.in(hash)  --
%% a.in({ alpha => 1, bravo => 1 }) ? j : k
-- expect --
juliet

-- test text.in(hash) not --
%% a.in({ charlie => 1, delta => 1 }) ? j : k
-- expect --
kilo

-- test text.in(named_params) --
%% a.in(bravo=1,alpha=2) ? l : m
-- expect --
# This test is broken because the in() vmethod doesn't recognise PARAMS
# We need to re-address the whole PARAMSissue for this reason.
lima

-- test text.in(named_params) not --
%% a.in(x=1,y=2) ? l : m
-- expect --
# This test passes but for the wrong reason - see above
mike

-- test text.in(named_params) not again --
%% [l,m,n].item( b.in(alpha=0,bravo=1,charlie=2) )
-- expect --
# This test fails - see above
mike



#-----------------------------------------------------------------------
# check we can use reserved words, terminators, etc has dotops
#-----------------------------------------------------------------------

-- test keyword dotops --
%% hash = { 'for' => f, 'if' => i }  hash.for hash.if
-- expect --
foxtrotindia

-- test terminator dotops --
%% hash = { 'in' => 'foo' }  hash.in
-- expect --
foo

-- test operator dotops --
%% hash = { 'and' => 'Dent', 'or' => 'Arthur' }  hash.and hash.or hash.and
-- expect --
DentArthurDent

