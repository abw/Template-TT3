#============================================================= -*-perl-*-
#
# t/provider/providers.t
#
# Test the Template::TT3::Providers module.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use lib 
    '/home/abw/projects/badger/lib';            # testing Badger changes
    
use Badger 
    lib        => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug   => 'Template::TT3::Providers',
    args    => \@ARGV,
    tests   => 7;

use constant 
    PROVIDERS => 'Template::TT3::Providers';

use Template::TT3::Providers;
pass( 'loaded Template::TT3::Providers' );


# get default provider
my $provider = PROVIDERS->provider;
ok( $provider, 'got default provider' );
is( ref $provider, 'Template::TT3::Provider::Cwd', 'got default Cwd provider' );

# get specific provider
$provider = PROVIDERS->provider( file => { root => Bin } );
ok( $provider, 'got file provider' );
is( ref $provider, 'Template::TT3::Provider::File', 'got file provider module' );

# in capitals this time
$provider = PROVIDERS->provider( File => { root => Bin } );
ok( $provider, 'got File provider' );
is( ref $provider, 'Template::TT3::Provider::File', 'got File provider module' );



