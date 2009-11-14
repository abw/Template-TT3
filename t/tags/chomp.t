#============================================================= -*-perl-*-
#
# t/tags/chomp.t
#
# Test script for tag chomping options.
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
    tests   => 26,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

#-----------------------------------------------------------------------
# pre chomp
#-----------------------------------------------------------------------

-- test no chomp --
Hello [% a %]
-- expect --
Hello alpha

-- test pre-chomp chomp_one at start --
-- preserve_ws --
[%- a %]
-- expect --
alpha

-- test pre-chomp chomp_one at start with spaces --
-- preserve_ws --
   [%- a %]
-- expect --
alpha

-- test pre-chomp chomp_one --
Hello 
[%- a %]
-- expect --
Hello alpha

-- test pre-chomp chomp_one with multi lines --
Hello 

[%- a %]
-- expect --
Hello 
alpha

-- test pre-chomp chomp_all --
Hello   
[%~ b %]
-- expect --
Hellobravo

-- test pre-chomp chomp_all with multi lines --
Hello   
   
   
[%~ c %]
-- expect --
Hellocharlie

-- test pre-chomp chomp_all with two tags --
[% a %]
   
  [%~ b %]
-- expect --
alphabravo


-- test pre-chomp chomp_space at start --
-- preserve_ws --
[%= d %]
-- expect --
 delta

-- test pre-chomp chomp_space at start with spaces --
-- preserve_ws --
   [%= d %]
-- expect --
 delta

-- test pre-chomp chomp_space with no space --
Hello[%= d %]
-- expect --
Hello delta

-- test pre-chomp chomp_collapse with some space --
Hello   [%= d %]
-- expect --
Hello delta

-- test pre-chomp chomp_collapse with one line --
Hello
[%= d %]
-- expect --
Hello delta

-- test pre-chomp chomp_collapse with multi lines --
Hello   
    
      
[%= d %]
-- expect --
Hello delta

-- test pre-chomp chomp_collapse with two tags --
[% a %]  
   
[%= b %]
-- expect --
alpha bravo


#-----------------------------------------------------------------------
# post-chomp
#-----------------------------------------------------------------------

-- test post-chomp chomp one --
[% a -%]
bravo
-- expect --
alphabravo

-- test post-chomp chomp_one with multi lines --
[% a -%]

bravo 
-- expect --
alpha
bravo

-- test post-chomp chomp_all --
[% b ~%]
charlie   
-- expect --
bravocharlie

-- test post-chomp chomp_all with multi lines --
[% c ~%]


delta
-- expect --
charliedelta

-- test post-chomp chomp_all with two tags --
[% a ~%]
   
  [%~ b %]
-- expect --
alphabravo

-- test post-chomp chomp_space with no space --
[% d =%][% e %]
-- expect --
delta echo

-- test post-chomp chomp_collapse with some space --
[% f =%]      [% g %]
-- expect --
foxtrot golf

-- test post-chomp chomp_collapse with one line --
[% h =%]
[% i %]
-- expect --
hotel india

-- test post-chomp chomp_collapse with multi lines --
[% j =%]
    
      
[% k %]
-- expect --
juliet kilo



#-----------------------------------------------------------------------
# comments
#-----------------------------------------------------------------------

-- test comment --
He[%# foo %]llo
-- expect --
Hello

-- test big comment --
He[%#
    # foo 
    # bar
    # baz
  %]llo
-- expect --
Hello
