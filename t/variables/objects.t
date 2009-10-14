#============================================================= -*-perl-*-
#
# t/variables/objects.t
#
# Tests for template variables that reference objects.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 17,
    debug => 'Template::TT3::Variables',
    args  => \@ARGV;

use Template::TT3::Variables;
use constant VARS => 'Template::TT3::Variables';

#-----------------------------------------------------------------------
# dummy object
#-----------------------------------------------------------------------

package Object1;

use Badger::Class
    base     => 'Badger::Base',
    mutators => 'foo bar';

sub init {
    my ($self, $config) = @_;
    $self->{ foo } = $config->{ foo } || 0;
    return $self;
}

sub inc_foo {
    my $self = shift;
    $self->{ foo } ||= 0;
    ++$self->{ foo };
}

sub hello {
    my $self = shift;
    my $name = shift || 'World';
    return "Hello $name";
}

sub _secret {
    'this is secret';
}

#-----------------------------------------------------------------------
# main tests
#-----------------------------------------------------------------------

package main;
    
my $data = {
    obj => Object1->new,
};

my $vars = VARS->new( data => $data );
ok( $vars, 'created variables stash' );

my $obj = $vars->var('obj');
ok( $obj, "got an object var: $obj" );
ok( $obj->ref, 'object is a ref: ' . $obj->ref );


#-----------------------------------------------------------------------
# call foo method
#-----------------------------------------------------------------------

my $result = $obj->dot('foo');
ok( $result, "got obj.foo result: $result" );
is( $result->value, 0, 'obj.foo returned zero' );

$obj->dot('inc_foo');
is( $obj->dot('foo')->value, 1, 'obj.foo now returns 1' );

is( $obj->dot('hello')->value, 'Hello World', 'Hello World' );
is( $obj->dot('hello', ['Badger'])->value, 'Hello Badger', 'Hello Badger' );


#-----------------------------------------------------------------------
# custom method map
#-----------------------------------------------------------------------

$vars = VARS->new( 
    data  => $data,
    types => {
        Object1 => {
            module   => 'Template::TT3::Variable::Object',
            methods  => {
                '*'      => 0,
                '_'      => 1,
                foo      => 1,
                more_foo => 'inc_foo',
                add_ten  => sub {
                    return shift->{ foo } + 10;
                },
            },
        },
    },
);

ok( $vars, 'created variables stash with custom types' );
$obj = $vars->var('obj');
ok( $obj, "got object var again: $obj" );


#-----------------------------------------------------------------------
# should be able to call foo(), more_foo() and add_ten() methods
#-----------------------------------------------------------------------

is( $obj->dot('foo')->value, 1, 'obj.foo method returns 1' ); 
is( $obj->dot('more_foo')->value, 2, 'called obj.more_foo method' ); 
is( $obj->dot('foo')->value, 2, 'obj.foo method returns 2' ); 
is( $obj->dot('add_ten')->value, 12, 'obj.add_ten method returns 12' ); 


#-----------------------------------------------------------------------
# calling bar method should fail
#-----------------------------------------------------------------------

ok( ! $obj->try->dot('bar'), 'cannot call obj.bar' ); 
is( $obj->reason->info, 'Access denied to object method: obj.bar', 'denied error message' ); 

is( $obj->dot('_secret')->value, 'this is secret', 'called secret method' ); 



__END__
ok( $result, "got obj.foo result: $result" );
is( $result->value, 0, 'obj.foo returned zero' );

$obj->dot('inc_foo');
is( $obj->dot('foo')->value, 1, 'obj.foo now returns 1' );

is( $obj->dot('hello')->value, 'Hello World', 'Hello World' );
is( $obj->dot('hello', ['Badger'])->value, 'Hello Badger', 'Hello Badger' );

