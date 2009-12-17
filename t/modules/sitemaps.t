#============================================================= -*-perl-*-
#
# t/modules/sitemaps.t
#
# Test the Template::TT3::Site::Maps module.
#
# Run with the -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug => 'Template::TT3::Site::Maps',
    args  => \@ARGV,
    tests => 2;

use Template::TT3::Site::Maps;
use constant SITEMAPS => 'Template::TT3::Site::Maps';

pass( 'Loaded ' . SITEMAPS );

my $data = SITEMAPS->sitemap( data => { test => 'Hello World' } );
ok( $data, 'created new data map' );


