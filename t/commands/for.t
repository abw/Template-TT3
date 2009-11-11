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
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

my $vars = callsign;
$vars->{ foo } = 10;
$vars->{ bar } = 20;

test_expressions(
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test for [a b] --
for [a, b]; 'item: '; item; '  '; end; 'done'
-- expect -- 
item: alpha  item: bravo  done

-- test list generator --
[item * 3 for [1, 3, 5]].join
-- expect --
3 9 15

-- test list generator with guard --
-- block --
[   for [1, 2, 3, 4, 5, 6];
        if item < 5;
            item * 2;
        end;
    end 
].join
-- expect --
2 4 6 8

-- test list generator with braces --
-- block --
[   for [1, 2, 3, 4, 5, 6] {
        if item < 5 {
            item * 2
        }
    }
].join
-- expect --
2 4 6 8

-- test list generator with single block expressions --
-- block --
[   for [1, 2, 3, 4, 5, 6] 
        if item < 5
            item * 2
].join
-- expect --
2 4 6 8

-- test list generator with guard in side-effect --
-- block --
[   item * 3 
        if item < 5
            for [1, 2, 3, 4, 5, 6]
].join
-- expect --
3 6 9 12

