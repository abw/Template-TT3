#============================================================= -*-perl-*-
#
# t/class/factory.t
#
# Test the Template::TT3::Class::Factory metaprogramming module
# for factory class construction.
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
    debug => 'Template::TT3::Class::Factory',
    args  => \@ARGV,
    tests => 5;

use Template::TT3::Class::Factory;
use constant CLASS => 'Template::TT3::Class::Factory';
pass( 'loaded ' . CLASS );


package Template::TT3::Test::Factory;

use Template::TT3::Class::Factory
    item => 'widget',
    path => 'Template(X)::(TT3::|)Widget';

package main;

my $factory = Template::TT3::Test::Factory->new;
ok( $factory, 'created widget factory' );

my $path = $factory->path;
ok( $path, 'got factory path' );
is( scalar(@$path), 4, 'four items in path' );
is( $path->[0], 'Template::TT3::Widget', 'first path item is correct' );

