#============================================================= -*-perl-*-
#
# t/expressions/variables.t
#
# Test script for variables.
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
    tests   => 42,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

our $vars  = {
    %{ callsign() },
    foo => sub {
        return 'called foo(' . join(', ', @_) .')';
    },
    call_foo => sub {
        my $foo = shift;
        return ref $foo eq 'CODE'
            ? 'call_foo: ' . $foo->(@_)
            : "cannot call foo (not a code ref): " . join(', ', $foo, @_);
    },
    one_thing => sub {
        return 'called one_thing(' . join(', ', @_) . ')';
    },
    many_things => sub {
        my @list = ('called many_things(', @_, ')');
        return @list;
    },
    some_things => sub {
        return wantarray
            ? ('called @some_things(', @_, ')')
            : 'called $some_things(' . join(', ', @_) . ')';
    },
    some_list => sub {
        my @list = wantarray
            ? ('called @some_list(', @_, ')')
            : ('called $some_list(', @_, ')');
        return wantarray
            ? @list
            : \@list;
    },
};

test_expressions(
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

#-----------------------------------------------------------------------
# simple variables
#-----------------------------------------------------------------------

-- test a --
a
-- expect --
alpha

-- test a() --
a()
-- expect --
alpha

-- test a(b,c) --
a(b,c)
-- expect --
alpha

-- test foo --
foo
-- expect --
called foo()

-- test foo() --
foo()
-- expect --
called foo()

-- test foo (a) --
foo (a)
-- expect --
called foo()alpha

-- test foo(a,b) --
foo(a,b)
-- expect --
called foo(alpha, bravo)

-- test call_foo(foo,x,y) --
# foo should be passed to call_foo() as a code reference
call_foo(foo,a,b)
-- expect --
call_foo: called foo(alpha, bravo)

-- test call_foo(foo,x,y) --
# the result of calling foo() should be passed to call_foo
call_foo(foo(),a,b)
-- expect --
cannot call foo (not a code ref): called foo(), alpha, bravo

-- test implicit scalar call on scalar sub --
one_thing
one_thing()
-- expect --
called one_thing()
called one_thing()

-- test implicit scalar call on polymorphic sub --
some_things
some_things()
-- expect --
called $some_things()
called $some_things()

#-----------------------------------------------------------------------
# The '$' sigil forces scalar context.  Scalar context is the default 
# so it's rarely required for normal variable access.  It's also used to 
# force the parser to recognise the next work as a variable.  This allows 
# you to access variables that have the same name as keywords, e.g. $fill
#-----------------------------------------------------------------------

-- test $a --
$a
-- expect --
alpha

-- test $foo --
$foo
-- expect --
called foo()

-- test $foo() --
$foo()
-- expect --
called foo()

-- test $foo (a) --
$foo (a)
-- expect --
called foo()alpha

-- test $foo(a,b) --
$foo(a,b)
-- expect --
called foo(alpha, bravo)

-- test explciit scalar call on scalar sub --
$one_thing
$one_thing()
-- expect --
called one_thing()
called one_thing()

-- test explicit scalar call on polymorphic sub --
$some_things
$some_things()
-- expect --
called $some_things()
called $some_things()


#-----------------------------------------------------------------------
# The '@' sigil forces lists context.  If the next item is a function 
# or object method then it will be called in list context rather than
# the default scalar context.  If the next item is a reference to a 
# list then it will be unpacked.  For any other items it will simply
# return the item (TODO: think about @hash returning values)
#-----------------------------------------------------------------------

-- test @a --
@a
-- expect --
alpha

-- test explicit list call on scalar sub with no args --
@one_thing
-- expect --
called one_thing()

-- test explicit list call on scalar sub with empty args --
@one_thing()
-- expect --
called one_thing()

-- test explicit list call on scalar sub with one arg --
@one_thing(a)
-- expect --
called one_thing(alpha)

-- test explicit list call on scalar sub with two args --
@one_thing(a,b)
-- expect --
called one_thing(alpha, bravo)

-- test explicit list call on list sub with no args --
@many_things
-- expect --
called many_things()

-- test explicit list call on list sub with empty args --
@many_things()
-- expect --
called many_things()

-- test explicit list call on list sub with one arg --
@many_things(a)
-- expect --
called many_things(alpha)

-- test explicit list call on list sub with many args --
@many_things(a,b,c,d)
-- expect --
# note that we're getting back a number of items here which are 
# being concatenated together
called many_things(alphabravocharliedelta)

-- test explicit list call on polymorphic sub --
@some_things
@some_things()
-- expect --
called @some_things()
called @some_things()


#-----------------------------------------------------------------------
# assigning results to variables
#-----------------------------------------------------------------------

-- test assign scalar call to variable --
foo = one_thing(); 'foo = '; foo
-- expect --
foo = called one_thing()

-- test assign scalar call to variable --
foo = some_things(a); 'foo = '; foo
-- expect --
foo = called $some_things(alpha)

-- test assign list call to scalar variable --
# Functions are called in scalar context by default.  That means that 
# anything returning a list will now yield the list size...
foo = many_things(a); 'foo = '; foo
-- expect --
foo = 3

-- test capture list call in list --
foo = [many_things(a,b)]; 'foo size is '; foo.size ' => ' foo.join
-- expect --
foo size is 1 => 4

-- test assign explicit list call to scalar variable --
# so we now use '@' to indicate list context
foo = [@many_things(a,b)]; 'foo size is '; foo.size ' => ' foo.join
-- expect --
foo size is 4 => called many_things( alpha bravo )
-- expect --
foo = 3

-- test scalar call on list sub captured in list --
-- block --
list = [@many_things()];
'[' list.0 ']'
-- expect --
[called many_things(]

-- test list call on list sub captured in list --
-- block --
list = [@many_things];
'[' list.0 '] ['list.1 ']'
-- expect --
[called many_things(] [)]

-- test list call on list sub captured in list with args--
-- block --
list = [@many_things(a,b)];
'[' list.0 '] [' list.1 '] [' list.2 '] [' list.3 ']'
-- expect --
[called many_things(] [alpha] [bravo] [)]

-- test list call on list sub assign to scalar --
-- block --
list = @many_things;
'[' list.0 '] ['list.1 ']'
-- expect --
[called many_things(] [)]

-- test single assign to single return --
-- block --
item = @one_thing(a,b);
'item: ' item
-- expect --
item: called one_thing(alpha, bravo)

-- test some_list() --
text = some_list(); text.join
-- expect --
called $some_list( )

-- test @some_list() --
@some_list()
-- expect --
called @some_list()

-- test @$some_list() --
@$some_list()
-- expect --
called $some_list()

-- test @$some_list() --
list = [@$some_list()]; list.size ' / ' list.0 ' / ' list.1
-- expect --
2 / called $some_list( / )
