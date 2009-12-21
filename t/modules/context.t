#============================================================= -*-perl-*-
#
# t/modules/context.t
#
# Test the Template::TT3::Context module.
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
    debug => 'Template::TT3::Context',
    args  => \@ARGV,
    tests => 65;

use Template::TT3::Context;
use constant CONTEXT => 'Template::TT3::Context';

ok( 1, 'loaded Template::TT3::Context' );

my $context = CONTEXT->new;
ok( $context, 'created context object' );


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
# define some data
#-----------------------------------------------------------------------

package main;

my $data = {
    a       => 10,
    b       => { c => 20 },
    d       => [ 1.618, 2.718, 3.142 ],
    e       => { f => { g => { h => [ 'hello world' ] } } },
    one     => sub { 1 },
    inc     => sub { my ($a) = @_; $a + 1 },
    add     => sub { my ($a, $b) = @_; $a + $b },
    hello   => \&hello,
    say     => {
        hello => \&hello,
    },
};

sub hello {
    my $name = shift || 'World';
    return "Hello $name";
}

$context = CONTEXT->new( data => $data );
ok( $context, 'created context' );


#-----------------------------------------------------------------------
# simple scalar
#-----------------------------------------------------------------------

my $a = $context->var('a');
ok( $a, "got a var: $a" );
ok( ! $a->ref, 'a is not a ref' );
is( $a->get, 10, 'a is 10' );


#-----------------------------------------------------------------------
# simple hash
#-----------------------------------------------------------------------

my $b = $context->var('b');
ok( $b, "got b var: $b" );
is( $b->ref, 'HASH', 'b is a HASH ref' );

my $c = $b->dot('c');
ok( $c, "got b.c var: $c" );
ok( ! $c->ref, 'b.c is not a ref' );
is( $c->get, 20, 'b.c is 20' );


#-----------------------------------------------------------------------
# simple list
#-----------------------------------------------------------------------

my $d = $context->var('d');
ok( $d, "got d var: $d" );
is( $d->ref, 'ARRAY', 'd is an ARRAY ref' );
is( $d->dot(0)->get, 1.618, 'd.0 is 1.618' );
is( $d->dot(1)->get, 2.718, 'd.1 is 2.718' );
ok( ! $d->try->dot('poop'), 'cannot dot poop' );
is( $d->reason->info, '"poop" is not a valid list method in "d.poop"', 'got error message' );


#-----------------------------------------------------------------------
# complex hash/list
#-----------------------------------------------------------------------

is( 
    $context->var('e')->dot('f')->dot('g')->dot('h')->dot('0')->get, 
    'hello world', 
    'e.f.g.h.0 is hello world' 
);


#-----------------------------------------------------------------------
# code ref
#-----------------------------------------------------------------------

my $one = $context->var('one');
is( $one->ref, 'CODE', 'one is a code ref' );
is( ref $one->value, 'CODE', 'one value is a code ref');

my $result = $one->apply;
ok( $result, 'got result from applying one' );
is( $result->value, 1, 'one applied to give 1');


#-----------------------------------------------------------------------
# code refs called with arguments
#-----------------------------------------------------------------------

is( $context->var('inc')->apply(10)->value, 11, 'inc(10) gives 11');
is( $context->var('add')->apply(10,20)->value, 30, 'add(10,20) gives 30');

my $fn = $context->var('hello');
is( $fn->ref, 'CODE', 'hello is code' );
is( $fn->apply->value, 'Hello World', 'hello() => Hello World' );
is( $fn->apply('Badger')->value, 'Hello Badger', 'hello("Badger") => Hello Badger' );

$fn = $context->var('say')->dot('hello');
is( $fn->ref, 'CODE', 'say.hello is code' );

is( $fn->apply->value, 'Hello World', 'say.hello() => Hello World' );
is( $fn->apply('Badger')->value, 'Hello Badger', 'say.hello("Badger") => Hello Badger' );

$result = $fn = $context->var('say')->dot('hello' => ['Ferret']);
is( $result->value, 'Hello Ferret', 'say.hello("Ferret") => Hello Ferret' );



#-----------------------------------------------------------------------
# with()
#-----------------------------------------------------------------------

my $parent = CONTEXT->new( data => { a => 10, b => 20  } );
is( $parent->var('a')->value, 10, 'a is 10 in parent of with()' );
is( $parent->var('b')->value, 20, 'b is 10 in parent of with()' );

my $child = $parent->with( a => 15, c => 30 );
is( $child->var('a')->value, 15, 'a is 15 in child of with()' );
is( $child->var('b')->value, 20, 'b is 10 in child of with()' );
is( $child->var('c')->value, 30, 'c is 10 in child of with()' );
is( $parent->var('a')->value, 10, 'a is still 10 in parent of with()' );
is( $parent->var('b')->value, 20, 'b is still 10 in parent of with()' );



#-----------------------------------------------------------------------
# just()
#-----------------------------------------------------------------------

$parent = CONTEXT->new( data => { a => 10, b => 20  } );
is( $parent->var('a')->value, 10, 'a is 10 in parent of just()' );
is( $parent->var('b')->value, 20, 'b is 10 in parent of just()' );

$child = $parent->just( a => 15, c => 30 );
is( $child->var('a')->value, 15, 'a is 15 in child of just()' );
ok( ! defined $child->var('b')->maybe, 'b is not defined in child of just()' );
is( $child->var('c')->value, 30, 'c is 10 in child of just()' );
is( $parent->var('a')->value, 10, 'a is still 10 in parent of just()' );
is( $parent->var('b')->value, 20, 'b is still 10 in parent of just()' );



#-----------------------------------------------------------------------
# auto_var()
#-----------------------------------------------------------------------

sub auto_var {
    my ($context, $name) = @_;
    return "default value for $name";
}

$child->auto_var(\&auto_var);
is( $child->var('foo')->value, 'default value for foo', 'auto handler' );


#-----------------------------------------------------------------------
# objects
#-----------------------------------------------------------------------

package main;
    
$data = {
    obj => Object1->new,
};

$context = CONTEXT->new( data => $data );
ok( $context, 'created variables stash' );

my $obj = $context->var('obj');
ok( $obj, "got an object var: $obj" );
ok( $obj->ref, 'object is a ref: ' . $obj->ref );


#-----------------------------------------------------------------------
# call foo method
#-----------------------------------------------------------------------

$result = $obj->dot('foo');
ok( $result, "got obj.foo result: $result" );
is( $result->value, 0, 'obj.foo returned zero' );

$obj->dot('inc_foo');
is( $obj->dot('foo')->value, 1, 'obj.foo now returns 1' );

is( $obj->dot('hello')->value, 'Hello World', 'Hello World' );
is( $obj->dot('hello', ['Badger'])->value, 'Hello Badger', 'Hello Badger' );


#-----------------------------------------------------------------------
# custom method map
#-----------------------------------------------------------------------

$context = CONTEXT->new( 
    data  => $data,
    types => {
        Object1 => {
#           module   => 'Template::TT3::Variable::Object',
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

ok( $context, 'created variables stash with custom types' );
$obj = $context->var('obj');
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



#-----------------------------------------------------------------------
# undefined and missing values
#-----------------------------------------------------------------------

my $missing = $context->var('lord_lucan');
ok(! $missing->try->text, 'could not find Lord Lucan' );
is( $@->info, '"lord_lucan" is missing', 'Lord Lucan is missing' );


__END__
ok( $result, "got obj.foo result: $result" );
is( $result->value, 0, 'obj.foo returned zero' );

$obj->dot('inc_foo');
is( $obj->dot('foo')->value, 1, 'obj.foo now returns 1' );

is( $obj->dot('hello')->value, 'Hello World', 'Hello World' );
is( $obj->dot('hello', ['Badger'])->value, 'Hello Badger', 'Hello Badger' );



