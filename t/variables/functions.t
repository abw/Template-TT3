#============================================================= -*-perl-*-
#
# t/variables/functions.t
#
# Tests for template variables that reference functions (code).
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 8,
    debug => 'Template::TT3::Variables',
    args  => \@ARGV;

use Template::TT3::Variables;
use constant VARS => 'Template::TT3::Variables';

sub hello {
    my $name = shift || 'World';
    return "Hello $name";
}


my $data = {
    hello => \&hello,
    say   => {
        hello => \&hello,
    }
};

my $vars = VARS->new( data => $data );
ok( $vars, 'created variables stash' );


#-----------------------------------------------------------------------
# fetch function references
#-----------------------------------------------------------------------

my $fn = $vars->var('hello');
is( $fn->ref, 'CODE', 'hello is code' );
is( $fn->apply->value, 'Hello World', 'hello() => Hello World' );
is( $fn->apply('Badger')->value, 'Hello Badger', 'hello("Badger") => Hello Badger' );

$fn = $vars->var('say')->dot('hello');
is( $fn->ref, 'CODE', 'say.hello is code' );

is( $fn->apply->value, 'Hello World', 'say.hello() => Hello World' );
is( $fn->apply('Badger')->value, 'Hello Badger', 'say.hello("Badger") => Hello Badger' );

my $result = $fn = $vars->var('say')->dot('hello' => ['Ferret']);
is( $result->value, 'Hello Ferret', 'say.hello("Ferret") => Hello Ferret' );
