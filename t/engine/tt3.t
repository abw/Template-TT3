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
    lib        => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug   => 'Template::TT3::Engine::TT3 Template::TT3::Templates',
    args    => \@ARGV,
    tests   => 16;



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


#-----------------------------------------------------------------------
# fetch a template from text
#-----------------------------------------------------------------------

my $template = $tt3->template( text => 'Hello [% name or "World" %]!' )
    || die $tt3->reason;
ok( $template, 'fetched template from text' );
ok( $template->id, 'template id is ' . $template->id );
ok( $template->hub, 'template hub is ' . $template->hub );
ok( $template->dialect, 'template dialect is ' . $template->dialect );
ok( $template->templates, 'template templates is ' . $template->templates );

is( 
    $template->fill,                        # A bit of TT3 history in the 
    'Hello World!',                         # making - this was the first full
    'processed Hello World template text'   # template TT3 ever processed!
);
is( 
    $template->fill( name => 'Badger' ), 
    'Hello Badger!', 
    'processed Hello Badger template text'
);



#-----------------------------------------------------------------------
# create an engine with a template_path
#-----------------------------------------------------------------------

package main;

$tt3 = TT3->new( 
    template_path => Bin->dir('templates') 
);
ok( $tt3, 'created template engine with custom template_path' );


$template = $tt3->template( file => 'hello.tt3' )
    || die $tt3->reason;
    
ok( $template, 'fetched hello.tt3 template from file' );


is( 
    $template->fill,                    # This was the first template file
    "Hello World!\n",                   # TT3 ever processed.
    'processed Hello World template file'
);
is( 
    $template->fill( name => 'Badger' ), 
    "Hello Badger!\n", 
    'processed Hello Badger template file'
);



