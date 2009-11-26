#============================================================= -*-perl-*-
#
# t/expressions/params.t
#
# Test script for parenthesised expressions.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

#use Badger::Debug modules => 'Template::TT3::Utils';

use Template::TT3::Test 
    tests   => 2,
    debug   => 'Template::TT3::Utils',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    full_error => 1,
    debug      => DEBUG,
    variables  => callsign,
);


__DATA__

-- test params expansion --
%% foo(%p) = 'params: ' ~ { %p }.keys.sort.join(', '); foo(a=10 b=20)
-- expect -- 
params: a, b

-- test multiple params expansion --
%% foo(A,B)  = 'params: ' ~ { %A %B }.keys.sort.join(', ')
%% foo(A={a=10},B={b=20}) "\n"
%% bar(C,%D) = foo(A=C,B=D)
%% bar({a=10}, b=20, c=30) "\n"
%% baz(%A)   = bar(A, x=98, y=99, z=100)
%% baz(a=10 b=20 c=30)
-- expect -- 
params: a, b
params: a, b, c
params: a, b, c, x, y, z
