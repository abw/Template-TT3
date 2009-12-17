#============================================================= -*-perl-*-
#
# t/app/tt3.t
#
# Test the Template::TT3::App module.
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
    debug => 'Template::TT3::App',
    args  => \@ARGV,
    tests => 2;

use Template::TT3::App;
use constant APP => 'Template::TT3::App';

pass( 'Loaded ' . APP );

my $app = APP->new;
ok( $app, 'created an ' . APP . ' object' );

$app->args('-h');
