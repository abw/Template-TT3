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
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

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

test_expressions(
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test list.join --
list.join
-- expect --
10 20 30

-- test list.join(', ') --
list.join(', ')
-- expect --
10, 20, 30

-- test list.** --
list.**
-- expect --
<ERROR:Missing expression for '.'.  Got '**'>


-- test hash.fill --
# should be OK to use keyword as dotops without them having any special
# meaning
hash.fill
-- expect --
FILLED


-- test hash  .fill --
# should be OK to have spaces before (but not after) the dotop
hash    .fill
-- expect --
FILLED

-- test hash.keys.sort.join(', ') --
hash.keys.sort.join(', ')
-- expect --
e, fill, phi, pi