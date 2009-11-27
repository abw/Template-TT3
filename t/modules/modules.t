#============================================================= -*-perl-*-
#
# t/modules/modules.t
#
# Test the Template::TT3::Modules module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 2,
    debug => 'Template::TT3::Modules',
    args  => \@ARGV;

use Template::TT3::Modules ':all';

ok( 1, 'loaded Template::TT3::Modules' );
is( HUB_MODULE, 'Template::TT3::Hub', 'HUB_MODULE is Template::TT3::Hub' );



