#============================================================= -*-perl-*-
#
# t/modules/variables.t
#
# Test the Template::TT3::Variables module.
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
#    skip  => 'Functionality has (mostly) moved to Template::TT3::Context',
    debug => 'Template::TT3::Variables',
    args  => \@ARGV,
    tests => 37;

use Badger::Debug ':all';
use Template::TT3::Variables;
use constant VARS => 'Template::TT3::Variables';

my $ctors = VARS->constructors;
ok( $ctors, 'got constructors' );

#main->debug("ctors: ", main->dump_data($ctors));

$ctors = VARS->constructors(
    undef => 'missing',
    text => {
        foo => sub { 'FOO' },
        bar => sub { 'BAR' },
    },
    'Wiz::Bang' => {
        '*'   => 0,
        'foo' => 1,
        'bar' => sub { 'PRETENDING TO BE BAR' },
    }
);

ok( $ctors, 'got constructors with custom types' );
my $text = $ctors->{'Wiz::Bang'};
ok( $text, 'got custom Wiz::Bang type' );


#main->debug("ctors: ", main->dump_data($ctors));

#my $hash = VARS->variable( HASH => { x => 10 } );
#ok( $hash, 'got hash var ' . $hash );
#is( $hash->dot('x')->value, 10, 'got value x=10 from hash' );

__END__
my $data = {
    a => 10,
    b => {
        c => 20,
    },
    d => [ 1.618, 2.718, 3.142 ],
    e => { f => { g => { h => [ 'hello world' ] } } },
    one => sub { 1 },
    inc => sub { my ($a) = @_; $a + 1 },
    add => sub { my ($a, $b) = @_; $a + $b },
};

my $vars = VARS->new( data => $data );
ok( $vars, 'created variables stash' );

#-----------------------------------------------------------------------
# simple scalar
#-----------------------------------------------------------------------

my $a = $vars->var('a');
ok( $a, "got a var: $a" );
ok( ! $a->ref, 'a is not a ref' );
is( $a->get, 10, 'a is 10' );


#-----------------------------------------------------------------------
# simple hash
#-----------------------------------------------------------------------

my $b = $vars->var('b');
ok( $b, "got b var: $b" );
is( $b->ref, 'HASH', 'b is a HASH ref' );

my $c = $b->dot('c');
ok( $c, "got b.c var: $c" );
ok( ! $c->ref, 'b.c is not a ref' );
is( $c->get, 20, 'b.c is 20' );


#-----------------------------------------------------------------------
# simple list
#-----------------------------------------------------------------------

my $d = $vars->var('d');
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
    $vars->var('e')->dot('f')->dot('g')->dot('h')->dot('0')->get, 
    'hello world', 
    'e.f.g.h.0 is hello world' 
);


#-----------------------------------------------------------------------
# code ref
#-----------------------------------------------------------------------

my $one = $vars->var('one');
is( $one->ref, 'CODE', 'one is a code ref' );
is( ref $one->value, 'CODE', 'one value is a code ref');

my $result = $one->apply;
ok( $result, 'got result from applying one' );
is( $result->value, 1, 'one applied to give 1');


#-----------------------------------------------------------------------
# code refs called with arguments
#-----------------------------------------------------------------------

is( $vars->var('inc')->apply(10)->value, 11, 'inc(10) gives 11');
is( $vars->var('add')->apply(10,20)->value, 30, 'add(10,20) gives 30');



#-----------------------------------------------------------------------
# with()
#-----------------------------------------------------------------------

my $parent = VARS->new( data => { a => 10, b => 20  } );
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

$parent = VARS->new( data => { a => 10, b => 20  } );
is( $parent->var('a')->value, 10, 'a is 10 in parent of just()' );
is( $parent->var('b')->value, 20, 'b is 10 in parent of just()' );

$child = $parent->just( a => 15, c => 30 );
is( $child->var('a')->value, 15, 'a is 15 in child of just()' );
ok( ! defined $child->var('b')->maybe, 'b is not defined in child of just()' );
is( $child->var('c')->value, 30, 'c is 10 in child of just()' );
is( $parent->var('a')->value, 10, 'a is still 10 in parent of just()' );
is( $parent->var('b')->value, 20, 'b is still 10 in parent of just()' );



#-----------------------------------------------------------------------
# auto()
#-----------------------------------------------------------------------

sub auto {
    my ($vars, $name) = @_;
    return "default value for $name";
}

$child->auto(\&auto);
is( $child->var('foo')->value, 'default value for foo', 'auto handler' );



__END__


#$stash->var('missing')->dot('foo');
#$stash->var('e')->dot('f')->dot('g')->dot('h')->dot('parp');
#is( $a->get, 10, 'a is 10' );

#$stash->var( b => 20 );
