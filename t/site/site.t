#============================================================= -*-perl-*-
#
# t/site/site.t
#
# Test the Template::TT3::Site module.
#
# Run with the -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use lib '/home/abw/projects/badger/lib';   # abw testing

use Badger 
    lib => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug => 'Template::TT3::Site Template::TT3::Site::Map::File Badger::Filesystem::Visitor',
    args  => \@ARGV,
    tests => 6;

use Template::TT3::Site;
use constant SITE => 'Template::TT3::Site';

pass( 'Loaded ' . SITE );

my $file = Bin->dir('metadata')->file('site.yaml');
my $site = SITE->new( map => $file );
ok( $site, 'created new site' );

$site->build(
    verbose => 1,
    all     => 1,
#    colour  => 0,
);

