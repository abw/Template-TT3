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
    tests   => 29
    ,
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
bar = if not_defined.defined;
   'b is ' b
else '';
foo 
bar.true or ', no bar'
-- expect --
a is alpha, no bar

-- test if as postop true --
a if b
-- expect --
alpha

-- test if as postop false --
'[' a if not_defined.defined ']'
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

-- test else true --
if k { l } else { m }
-- expect --
lima

-- test else false --
if not k { l } else { m }
-- expect --
mike

-- test elsif with braces true --
if a { b } elsif d { e }
-- expect --
bravo

-- test elsif with braces false --
if not a { b } elsif d { e }
-- expect --
echo

-- test multi-elsif with first match --
if a { b } elsif c { d } elsif e { f }
-- expect --
bravo

-- test multi-elsif with second match --
if not a { b } elsif c { d } elsif e { f }
-- expect --
delta

-- test multi-elsif with third match --
if not a { b } elsif not c { d } elsif e { f }
-- expect --
foxtrot

-- test multi-elsif with no match --
if not a { b } elsif not c { d } elsif not e { f }
-- expect --

-- test multi-elsif and else with first if match --
if a { b } elsif c { d } elsif e { f } else { g }
-- expect --
bravo

-- test multi-elsif and else with second elsif match --
if not a { b } elsif c { d } elsif e { f } else { g }
-- expect --
delta

-- test multi-elsif and else with third elsif match --
if not a { b } elsif not c { d } elsif e { f } else { g }
-- expect --
foxtrot

-- test multi-elsif and else with else match --
if not a { b } elsif not c { d } elsif not e { f } else { g }
-- expect --
golf


-- test if/elsif/else block form with if match --
-- block --
if a; 
  b ' ' c; 
elsif d; 
  e ' ' f;
else;
  g ' ' h
end;
-- expect --
bravo charlie

-- test if/elsif/else block form with elsif match --
-- block --
if not a; 
  b ' ' c; 
elsif d; 
  e ' ' f;
else;
  g ' ' h
end;
-- expect --
echo foxtrot

-- test if/elsif/else block form with else match --
-- block --
if not a; 
  b ' ' c; 
elsif not d; 
  e ' ' f;
else;
  g ' ' h;
end;
-- expect --
golf hotel

-- test if/elsif/else single expressions with if match --
-- block --
if      k   l 
elsif   m   n 
elsif   o   p 
else        q
-- expect --
lima

-- test if/elsif/else single expressions with first elsif match --
-- block --
if      not k   l 
elsif       m   n 
elsif       o   p 
else            q
-- expect --
november

-- test if/elsif/else single expressions with second elsif match --
-- block --
if      not k   l 
elsif   not m   n 
elsif       o   p 
else            q
-- expect --
papa

-- test if/elsif/else single expressions with else match --
-- block --
if      not k   l 
elsif   not m   n 
elsif   not o   p 
else            q
-- expect --
quebec





