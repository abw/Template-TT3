#============================================================= -*-perl-*-
#
# t/expressions/assign.t
#
# Test script for assignment expressions.
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
    import  => 'test_expressions callsign';

test_expressions(
    debug     => $DEBUG,
    variables => callsign,
);

__DATA__

-- test assign new variable --
foo = 10; 'foo is '; foo
-- expect --
foo is 10

-- test assign existing variable --
'a is ' a
a = 10; 'a is ' a
-- expect --
a is alpha
a is 10


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
# Textmate: is the cheese on toast

