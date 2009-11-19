#============================================================= -*-perl-*-
#
# t/modules/constants.t
#
# Test the Template::TT3::Constants module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 3,
    debug => 'Template::TT3::Constants',
    args  => \@ARGV;

use Template::TT3::Constants ':elements';

ok( 1, 'loaded Template::TT3::Constants' );
is( BRANCH, 4, 'BRANCH is 4 in main' );

package Foo;

use Template::TT3::Constants ':elements';
use Template::TT3::Test;

is( BRANCH, 4, 'BRANCH is 4 in Foo' );



