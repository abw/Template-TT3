#============================================================= -*-perl-*-
#
# t/commands/if.t
#
# Test script for the 'if' command.
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
    tests   => 10,
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

-- test if a b --
if a b
-- expect -- 
bravo

-- test if a { b } --
if a { c }
-- expect -- 
charlie

-- test if a; d; e; end --
if a; d; e; end
-- expect -- 
deltaecho

-- test if with complex expression --
-- block --
if foo > 5 and bar + 9 < 30 {
    z
}
-- expect --
zulu


-- test assignment to if --
-- block --
foo = if a;
   'a is ' a
end;
bar = if not_defined;
   'b is ' b
end;
foo 
bar or ', no bar'
-- expect --
a is alpha, no bar

-- test if as postop true --
a if b
-- expect --
alpha

-- test if as postop false --
'[' a if not_defined ']'
-- expect --
[]

-- test if as postop zero --
'[' a if 0 ']'
-- expect --
[]

-- test value propagation --
-- block --
list = [a, [b,c] if d];
'size: '; list.size; 
'  last size: '; list.last.size;
'  last item: '; list.last.last
-- expect --
size: 2  last size: 2  last item: charlie

-- test value propagation with false expression --
-- block --
list = [a, [b,c] if 0];
'size: '; list.size; 
'  last size: '; list.last.size;
'  last item: '; list.last
-- expect --
size: 1  last size: 1  last item: alpha








