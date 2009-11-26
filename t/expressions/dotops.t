#============================================================= -*-perl-*-
#
# t/expressions/dotops.t
#
# Test script for dotops.
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
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars  = {
    %{ callsign() },
    list => [10, 20, 30],
    hash => {
        phi  => 1.618,
        e    => 2.718,
        pi   => 3.142,
        fill => 'FILLED',
    },
};

test_expect(
    full_error => 1,
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test list.join --
%% list.join
-- expect --
10 20 30

-- test list.join(', ') --
%% list.join(', ')
-- expect --
10, 20, 30

-- test list.** --
%% list.**
-- error --
TT3 syntax error at line 1 of "list.**" test:
    Error: Missing expression for '.'.  Got '**'
   Source: %% list.**
                   ^ here

-- test hash.fill --
# should be OK to use keyword as dotops without them having any special
# meaning
%% hash.fill
-- expect --
FILLED


-- test hash  .fill --
# should be OK to have spaces before (but not after) the dotop
%% hash    .fill
-- expect --
FILLED

-- test hash.keys.sort.join(', ') --
%% hash.keys.sort.join(', ')
-- expect --
e, fill, phi, pi

-- test undefined lhs of a dotop --
%% undef.length
-- error --
TT3 undefined data error at line 1 of "undefined lhs of a dotop" test:
    Error: Undefined value in 'undef.length': undef
   Source: %% undef.length
                   ^ here

-- test undefined rhs of a dotop --
%% hash.missing
-- error --
TT3 undefined data error at line 1 of "undefined rhs of a dotop" test:
    Error: Undefined value returned by expression: hash.missing
   Source: %% hash.missing
                  ^ here

-- test undefined middle of a dotop --
%% hash.missing.have.you.seen.my.cat
-- error --
TT3 undefined data error at line 1 of "undefined middle of a dotop" test:
    Error: Undefined value in 'hash.missing.have': hash.missing
   Source: %% hash.missing.have.you.seen.my.cat
                          ^ here
