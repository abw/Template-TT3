#============================================================= -*-perl-*-
#
# t/site/data.t
#
# Test the Template::TT3::Site module using a basic data definition
# for the sitemap.
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
    debug => 'Template::TT3::Site Template::TT3::Site::Map::Data',
    args  => \@ARGV,
    tests => 2;

use Template::TT3::Site;
use constant SITE => 'Template::TT3::Site';

pass( 'Loaded ' . SITE );

my $site = SITE->new( 
    dir => Bin,
    map => {
        site => {
            title   => 'My Web Site',
            author  => 'Andy Wardley',
            version => 3.14,
        },
        pages => {
            'index.html' => {
                name  => 'Home',
                title => 'Home Page',
            },
            'about.html' => {
                name => 'About',
            },
        },
    }
);
ok( $site, 'created new site' );

