#============================================================= -*-perl-*-
#
# t/modules/template3.t
#
# Test the Template3 module.
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
    debug => 'Template3',
    args  => \@ARGV,
    tests => 3;

use Template3;

my $tt3 = Template3->new;
ok( $tt3, 'created template engine' );
is( ref $tt3, 'Template::TT3::Engine::TT3', 'Template3() returns TT3 engine' );

my $fill = $tt3->template( text => 'Hello [% name %]' )->fill( name => 'Badger' );
is( $fill, 'Hello Badger', 'filled template' );


#package Template::TT3::Test::TT2Engine;
#use Template3 'TT2';


