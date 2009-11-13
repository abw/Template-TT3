#============================================================= -*-perl-*-
#
# t/controls/tags.t
#
# Test script for TAGS control directive.
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
    skip    => 'Control tags not implemented yet',
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

our $vars = callsign;

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test one --
Hello [% a %]
-- expect --
Hello alpha

-- test tags single string --
[? TAGS <* *> ?]
Hello <* a *>
-- expect --
Hello alpha


