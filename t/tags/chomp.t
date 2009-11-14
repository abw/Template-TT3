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
    tests   => 13,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test no chomp --
Hello [% a %]
-- expect --
Hello alpha

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



-- test pre-chomp chomp_collapse with no space --
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
