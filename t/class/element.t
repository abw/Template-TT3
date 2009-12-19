#============================================================= -*-perl-*-
#
# t/class/element.t
#
# Test the Template::TT3::Class::Element metaprogramming module
# for element class construction.
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
    debug => 'Template::TT3::Class::Element',
    args  => \@ARGV,
    tests => 3;

use Template::TT3::Class::Element;
use constant CLASS => 'Template::TT3::Class::Element';
pass( 'loaded ' . CLASS );


package Template::TT3::Element::Test::Foo;
use Template::TT3::Class::Element;

package main;
my $foo = Template::TT3::Element::Test::Foo->new;
is( $foo->type, 'test_foo', 'element has default type' );


package Template::TT3::Element::Test::Bar;
use Template::TT3::Class::Element
    type => 'barbar';

package main;
my $bar = Template::TT3::Element::Test::Bar->new;
is( $bar->type, 'barbar', 'element has custom type' );

