#============================================================= -*-perl-*-
#
# t/engine/tt3.t
#
# Test script for the Template::TT3:Engine::TT3 module.
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
    debug   => 'Template::TT3::Engine::TT3',
    args    => \@ARGV,
    tests   => 5;


#-----------------------------------------------------------------------
# basic load/new tests
#-----------------------------------------------------------------------

use Template::TT3::Engine::TT3;
pass( 'loaded Template::TT3::Engine::TT3' );

use constant TT3 => 'Template::TT3::Engine::TT3';

my $engine = TT3->new;
ok( $engine, 'created a new TT3 engine' );


#-----------------------------------------------------------------------
# import TT3 constant shortcut
#-----------------------------------------------------------------------

package Template::TT3::Test::LoadTT3;

use Template::TT3::Engine::TT3 'TT3';
use Template::TT3::Test;

my $tt3 = TT3->new;
is( TT3, 'Template::TT3::Engine::TT3', 'imported TT3 constant' );
ok( $tt3, 'created a new TT3 engine from imported constant' );


#-----------------------------------------------------------------------
# access the hub
#-----------------------------------------------------------------------

my $hub = $tt3->hub;
ok( $hub, "got hub from engine: $hub" );


exit;


#-----------------------------------------------------------------------
# fetch a template from text
#-----------------------------------------------------------------------

my $template = $tt3->template( text => 'Hello [% name or "World" %]' );
ok( $template, 'fetched template from text' );

