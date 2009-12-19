#============================================================= -*-perl-*-
#
# t/element/text.t
#
# Test the Template::TT3::Element::Text module.
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
    debug => 'Template::TT3::Element::Text',
    args  => \@ARGV,
    tests => 7;

use Template::TT3::Elements;
use Template::TT3::Element::Text;
use constant {
    ELEMENT  => 'Template::TT3::Element::Text',
    ELEMENTS => 'Template::TT3::Elements',
};
    
pass( 'loaded ' . ELEMENT );

my $text = ELEMENT->new(undef, undef, 'hello');
ok( $text, 'created a text element' );

is( $text->text, 'hello', 'got text text()');
is( $text->value, 'hello', 'got text value()');
is( $text->values, 'hello', 'got text values()');

$text = ELEMENTS->prototype->construct( text => 'world' );
ok( $text, 'constructed text element via element factory' );
is( $text->text, 'world', 'got text: world');
