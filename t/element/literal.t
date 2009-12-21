#============================================================= -*-perl-*-
#
# t/element/literal.t
#
# Test the Template::TT3::Element::Literal module.
#
# Run with the -h option for help.
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
    debug => 'Template::TT3::Element::Literal',
    args  => \@ARGV,
    tests => 7;

use Template::TT3::Element::Literal;
use Template::TT3::Elements;
use constant {
    ELEMENT => 'Template::TT3::Element::Literal',
    ELEMENTS => 'Template::TT3::Elements',
};
    
pass( 'loaded ' . ELEMENT );

my $literal = ELEMENT->new(undef, undef, 'hello');
ok( $literal, 'created a literal element' );

is( $literal->text, 'hello', 'got literal text()');
is( $literal->value, 'hello', 'got literal value()');
is( $literal->values, 'hello', 'got literal values()');

$literal = ELEMENTS->prototype->create( literal => 'world' );
ok( $literal, 'constructed literal element via element factory' );
is( $literal->text, 'world', 'got literal text(): world');
