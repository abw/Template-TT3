#============================================================= -*-perl-*-
#
# t/expressions/ranges.t
#
# Test script for numerical ranges.
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
    tests   => 5,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions';

test_expressions(
    debug => DEBUG,
);


__DATA__

-- test range 1..5 --
1..5
-- expect -- 
1 2 3 4 5

-- test range 1..5, 10..15 --
1..5, ' / ' 10..15
-- expect -- 
1 2 3 4 5 / 10 11 12 13 14 15

-- test range 6 to 10 --
[6 to 10].join
-- expect -- 
6 7 8 9 10

-- test range 1 to 5 --
[1..5, 10..15].join
-- expect -- 
1 2 3 4 5 10 11 12 13 14 15

-- test range [4 to 20].join --
[4 to 20].join
-- expect -- 
4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
