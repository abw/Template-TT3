#============================================================= -*-perl-*-
#
# t/variables/variable.t
#
# Test the Template::TT3::Variable module.
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
    debug => 'Template::TT3::Variable Template::TT3::Context',
    args  => \@ARGV,
    tests => 2;

use Template::TT3::Context;
use Template::TT3::Variable;
use constant {
    VARIABLE => 'Template::TT3::Variable',
    CONTEXT  => 'Template::TT3::Context'
};

pass( 'loaded ' . CONTEXT );

my $context = CONTEXT->new( 
    data => { 
        foo => 'hello world',
        bar => undef,
    } 
);
ok( $context, 'created runtime context' );

my $foo = $context->var('foo');
ok( $foo, 'got foo variable' );
ok( $foo->defined, 'foo is defined' );

my $bar = $context->var('bar');
ok( $bar, 'got bar variable' );
ok( ! $bar->defined, 'bar is not defined' );

my $baz = $context->var('baz');
ok( $baz, 'got baz variable' );
ok( ! $baz->defined, 'baz is not defined' );

print "foo: $foo\n";
print "bar: $bar\n";
print "baz: $baz\n";

# value() returns raw perl value, including explicit undef or missing variables
is( $foo->value, 'hello world', 'got foo value' );
ok( ! defined $bar->value, 'bar value is undefined' );
ok( ! defined $baz->value, 'baz value is undefined' );


# text() always requires a defined value
is( $foo->text, 'hello world', 'got foo text' );
ok( ! defined $bar->try->text, 'bar text failed' );
is( $@->info, '"bar" is undefined', 'got undefined data error' );
ok( ! defined $baz->try->text, 'baz text failed' );
is( $@->info, '"baz" is missing', 'got missing data error' );

