#============================================================= -*-perl-*-
#
# t/engine/customise.t
#
# Test script for customising engines.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use lib '/home/abw/projects/badger/lib';

use Badger 
    lib        => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug   => 'Template::TT3::Engine::TT3 Template::TT3::Templates',
    args    => \@ARGV,
    tests   => 2;



use Template::TT3::Engine::TT3;
pass( 'loaded Template::TT3::Engine::TT3' );

use constant TT3 => 'Template::TT3::Engine::TT3';


#-----------------------------------------------------------------------
# create an engine with custom tags
#-----------------------------------------------------------------------

my $tt3 = TT3->new( tags => '<* *>' );
my $output = $tt3->template( text => 'Hello <* name *>' )->fill( name => 'Badger' );
is( $output, 'Hello Badger', 'processed template with custom tags' );
