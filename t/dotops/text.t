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
    tests   => 27,
    debug   => 'Template::TT3::Template Template::TT3::Variables',
    args    => \@ARGV,
    import  => 'test_expressions';

test_expressions(
    debug     => $DEBUG,
#    dump_tokens => 1,
    variables => {
        foo => 'this is foo',
        bar => 'and this is bar',
    },
);


__DATA__

-- test foo.length --
foo.length
-- expect --
11

-- test foo.upper --
foo.upper
-- expect --
THIS IS FOO

-- test foo.split.join --
foo.split.join
-- expect --
this is foo

-- test foo.mushroom --
foo.mushroom
-- expect --
<ERROR:"mushroom" is not a valid text method in "foo.mushroom">

-- test 'snake'.length --
'snake'.length
-- expect --
5

-- test 'snake'.mushroom --
'snake'.mushroom
-- expect --
<ERROR:"mushroom" is not a valid text method in "'snake'.mushroom">


