#============================================================= -*-perl-*-
#
# t/modules/hub.t
#
# Test the Template::TT3::Hub module.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib';
    
use Template::TT3::Test 
    debug => 'Template::TT3::Hub',
    args  => \@ARGV,
    tests => 3;

use Template::TT3::Hub;
use constant HUB => 'Template::TT3::Hub';

ok( 1, 'loaded Template::TT3::Hub' );

# should be able to use it as a prototype/singleton
my $providers = HUB->providers;
ok( $providers, 'fetched providers' );

my $file = HUB->provider( file => { path => '/tmp' } );
ok( $file, 'fetched file provider' );


