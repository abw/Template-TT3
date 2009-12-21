#============================================================= -*-perl-*-
#
# t/modules/elements.t
#
# Test the Template::TT3::Elements module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 10,
    debug => 'Template::TT3::Elements',
    args  => \@ARGV;

use Template::TT3::Elements::Core;
use constant {
    ELEMS => 'Template::TT3::Elements',
};

ok( 1, 'loaded elements' );

my $elems = ELEMS->new;
ok( $elems, 'created elements object' );

my $op = $elems->constructor('number')->(10);
ok( $op, 'got number op' );
is( $op->value, 10, 'op value is 10' );

my $n1 = $elems->construct( number => 42 );
is( $n1->value, 42, 'n1 value is 42' );

my $n2 = $elems->construct( number => 69 );
is( $n2->value, 69, 'n2 value is 69' );

my $add = $elems->construct('number.add' => '+', 3, $n1, $n2 );
is( $add->value, 111, 'addition: 42 + 69 = 111' );

my $sub = $elems->construct('number.subtract' => '-', 4, $n2, $n1 );
is( $sub->value, 27, 'subtraction: 69 - 42 = 27' );

# test aliases 
$sub = $elems->construct( num_subtract => '-', 4, $n2, $n1 );
is( $sub->value, 27, 'num_subtract subtraction: 69 - 42 = 27' );

$sub = $elems->construct( number_subtract => '-', 4, $n2, $n1 );
is( $sub->value, 27, 'number_subtract subtraction: 69 - 42 = 27' );
