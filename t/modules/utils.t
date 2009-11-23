#============================================================= -*-perl-*-
#
# t/modules/utils.t
#
# Test the Template::TT3::Utils module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';

use Template::TT3::Test 
    tests => 4,
    debug => 'Template::TT3::Class',
    args  => \@ARGV;

use Template::TT3::Utils 'random_advice';

{
    local @Template::TT3::Utils::ADVICE = ('This is the only advice');
    is( random_advice(), 'This is the only advice', 'random_advice()' );
    is( random_advice(), 'This is the only advice', 'more random_advice()' );
    is( random_advice(), 'This is the only advice', 'even more random_advice()' );
    is( random_advice(), 'This is the only advice', 'yet another piece of random_advice()' );
}
