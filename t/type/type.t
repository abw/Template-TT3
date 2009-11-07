#============================================================= -*-perl-*-
#
# t/type/type.t
#
# Test the Template::TT3::Type module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug  => 'Template::TT3::Type',
    args   => \@ARGV,
    tests  => 15;

use Template::TT3::Type;
pass('loaded Template::TT3::Type');

my $Type = 'Template::TT3::Type';


#------------------------------------------------------------------------
# methods() and method() as class methods
#------------------------------------------------------------------------

my ($methods, $method);

$methods = $Type->methods();
ok( $methods, 'got methods table from methods()' );
is( ref $methods, 'HASH', 'methods is a hash from methods()' );
ok( defined $methods->{ new }, 'got new method from methods()' );

$methods = $Type->method();
ok( $methods, 'got methods table from method()' );
is( ref $methods, 'HASH', 'methods is a hash from method()' );
ok( defined $methods->{ new }, 'got new method from method()' );

$method = $Type->method('new');
ok( $method, 'got new() method direct from method()' );


#------------------------------------------------------------------------
# new() constructor method
#------------------------------------------------------------------------

my $obj;

$obj = $Type->new();
ok( $obj, 'created an object' );

$obj = $Type->new( pi => 3.14 );
ok( $obj, 'created a pi object' );
is( $obj->{ pi }, 3.14, 'pi is 3.14' );


#------------------------------------------------------------------------
# init() method
#------------------------------------------------------------------------

ok( $obj->init({ pi => 3.14159 }), 'called init() on object' );
is( $obj->{ pi }, 3.14159, 'pi is now 3.14159' );


#------------------------------------------------------------------------
# ref() and type()
#------------------------------------------------------------------------

is( $obj->ref(), 'Template::TT3::Type', 'object isa Template::TT3::Type' );
is( $obj->type(), 'type', 'object isa Type' );





__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
