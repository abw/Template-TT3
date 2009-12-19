#============================================================= -*-perl-*-
#
# t/factory/engines.t
#
# Test the Template::TT3::Engines factory module which loads and 
# instantiates engine modules.
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
    lib     => '../../lib';

use Template::TT3::Test 
    debug   => 'Template::TT3::Engines',
    args    => \@ARGV,
    tests   => 7;

use constant 
    ENGINES => 'Template::TT3::Engines';

use Template::TT3::Engines;
pass( 'loaded Template::TT3::Engines' );

# get default engine
my $engine = ENGINES->engine;
ok( $engine, 'got default engine' );
is( ref $engine, 'Template::TT3::Engine::TT3', 'got default TT3 engine module' );

# get specific engine
$engine = ENGINES->engine('tt3');
ok( $engine, 'got tt3 engine' );
is( ref $engine, 'Template::TT3::Engine::TT3', 'got tt3 engine module' );

# in capitals this time
$engine = ENGINES->engine('TT3');
ok( $engine, 'got TT3 engine' );
is( ref $engine, 'Template::TT3::Engine::TT3', 'got TT3 engine module' );

