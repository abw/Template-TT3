#============================================================= -*-perl-*-
#
# t/commands/dot.t
#
# Test script for the 'dot' command.
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
    tests   => 2,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test alpha dot length --
[% a dot length -%]
-- expect -- 
5

-- test dot truncate(3) --
[% a dot truncate(3) %]
-- expect --
alp

-- test dot length --
[% dot length a %]
-- expect --
5

-- test dot truncate(10) with block --
[% dot truncate(10) %][% a b c %][% end %]
-- expect --
alphabravo

-- test dot truncate(10) with inline block to end --
[% dot truncate(10); a b c; end %]
-- expect --
alphabravo

-- test dot truncate(10) with braced block to end --
[% dot truncate(10) { a b c } %]
-- expect --
alphabravo

-- test dot truncate(10) with single expression --
[% dot truncate(3) a %]
-- expect --
alp

-- test dot truncate(10) with single complex expression --
[% dot truncate(3) a ~ b ~ c %]
-- expect --
alp

-- test dot truncate(10) with single complex expression side effect --
[% a ~ b ~ c dot truncate(10) %]
-- expect --
alphabravo

-- start -- 

-- test multi-dot --
[% dot chunk(3).join(', ') a ~ b ~ c %]
-- expect --
alp, hab, rav, och, arl, ie

-- test multi-dot in side-effect --
[% a ~ b ~ c dot chunk(3).join(', ') %]
-- expect --
alp, hab, rav, och, arl, ie
