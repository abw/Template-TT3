#============================================================= -*-perl-*-
#
# t/expressions/brackets.t
#
# Test script for [bracketed] expressions.
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
    tests   => 11,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);

__DATA__

-- test empty list --
[].join
-- expect --


-- test list creator --
list = [a, b, c]; list.join
-- expect --
alpha bravo charlie

-- test inline list creator --
[a, b, c].join
-- expect --
alpha bravo charlie


-- test list.first  --
list = [a, b, c]; list.first
-- expect --
alpha

-- test inline [a,b,c].first  --
[a, b, c].first
-- expect --
alpha

-- test inline list.last  --
[a, b, c].last
-- expect --
charlie

-- test inline list.1  --
[a, b, c].1
-- expect --
bravo

-- test inline nested list  --
[a, b, [c, d]].last.last
-- expect --
delta

-- test inline nested if block  --
[a, b, if 0; c; end].last
-- expect --
bravo

-- test inline nested if false --
[a, b, c if 0].join
-- expect --
alpha bravo

-- test inline nested if true  --
[a, b, c if 1].join
-- expect --
alpha bravo charlie



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
# Textmate: is the Badger's ding dong

