#============================================================= -*-perl-*-
#
# t/factory/exceptions.t
#
# Test the Template::TT3::Exceptions factory module which loads and 
# instantiates exception objects used to represent errors.
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
    debug   => 'Template::TT3::Exceptions',
    args    => \@ARGV,
    tests   => 4;

use constant 
    FACTORY => 'Template::TT3::Exceptions';

use Template::TT3::Exceptions;
pass( 'loaded ' . FACTORY );

my $syntax = FACTORY->item( syntax => { info => 'just testing' } );
ok( $syntax, 'got syntax error' );
is( $syntax->type, 'syntax', 'got syntax error type' );
is( $syntax->info, 'just testing', 'got syntax error info' );

