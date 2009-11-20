#============================================================= -*-perl-*-
#
# t/type/code.t
#
# Test the Template::TT3::Type::Code module.
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
    debug  => 'Template::TT3::Type::Code',
    args   => \@ARGV,
    tests  => 7;

use Template::TT3::Type::Code qw(CODE Code);

is( CODE->type, 'Code', 'Code type' );
is( ref CODE->methods, 'HASH', 'Code methods' );


#-----------------------------------------------------------------------
# check CODE constant is defined and Code() subroutine to create Code
#-----------------------------------------------------------------------

is( CODE, 'Template::TT3::Type::Code', 'got CODE constant' );
my $inc = Code( sub { my $n = shift; $n + 1 } );
is( ref $inc, CODE, 'got Template::TT3::Type::Code object from Code()' );
is( $inc->type, 'Code', 'type is Code' );

#-----------------------------------------------------------------------
# call code
#-----------------------------------------------------------------------

is( $inc->(10), 11, 'this one goes up to eleven' );
is( $inc->call(10), 11, "it's one louder" );



