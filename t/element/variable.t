#============================================================= -*-perl-*-
#
# t/element/variable.t
#
# Test the Template::TT3::Element::Variable module.
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
    debug => 'Template::TT3::Element::Variable',
    args  => \@ARGV,
    tests => 7;

use Template::TT3::Elements;
use Template::TT3::Context;
use constant {
    ELEMENTS => 'Template::TT3::Elements',
    CONTEXT  => 'Template::TT3::Context',
};
    
pass( 'loaded ' . ELEMENTS );

my $elements = ELEMENTS->new;
ok( $elements, 'created elements factory' );

my $foo = $elements->construct( variable => 'foo' );
my $bar = $elements->construct( variable => 'bar' );
my $baz = $elements->construct( variable => 'baz' );

ok( $foo, 'created foo variable' );
is( $foo->token, 'foo', 'got foo token' );
ok( $bar, 'created bar variable' );
is( $bar->token, 'bar', 'got bar token' );
ok( $baz, 'created baz variable' );
is( $baz->token, 'baz', 'got baz token' );

my $context = CONTEXT->new( 
    data => { 
        foo => 'hello world',
        bar => undef,
    } 
);
ok( $context, 'created runtime context' );

# foo should yield the 'hello world' string as a value() and text()
is( $foo->value($context), 'hello world', 'got foo value' );
is( $foo->text($context), 'hello world', 'got foo text' );

# bar should yield undef for value() and throw an error for text()
ok( ! defined $bar->value($context), 'bar is not defined' );
ok( ! $bar->try->text($context), 'bar text threw error' );
is( $@,'blah blah error', 'got error for undefined value' );

# baz should yield undef for value() and throw a different error for text()
ok( ! defined $baz->value($context), 'baz is not defined' );
ok( ! $baz->try->text($context), 'baz text threw error' );
is( $@,'blah blah error', 'got error for missing value' );

