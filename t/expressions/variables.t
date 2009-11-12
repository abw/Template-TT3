#============================================================= -*-perl-*-
#
# t/expressions/variables.t
#
# Test script for variables.
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
    tests   => 4,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

our $vars = callsign;
$vars->{ foo } = sub {
    return 'foo(' . join(', ', @_) .')';
};

test_expressions(
    debug     => $DEBUG,
    variables => $vars,
);


__DATA__

-- test a --
a
-- expect --
alpha

-- test foo --
foo
-- expect --
foo()

-- test foo() --
foo()
-- expect --
foo()

-- test foo(a,b) --
-- skip Functions don't get called with args yet -- 
foo(a,b)
-- expect --
foo(alpha, bravo)

