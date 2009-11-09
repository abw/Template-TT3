#============================================================= -*-perl-*-
#
# t/modules/types.t
#
# Test the Template::TT3::Types module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use Badger::Debug modules => 'Badger::Factory';
use Badger lib => '../../lib';
use Template::TT3::Test 
    debug => 'Badger::Factory Template::TT3::Types',
    args  => \@ARGV,
    tests => 43;

use Template::TT3::Types;
use constant TYPES => 'Template::TT3::Types';

ok( TYPES->preload, 'preload' );


#------------------------------------------------------------------------
# create a Template::TT3::Type::Text object
#------------------------------------------------------------------------

my $text = TYPES->create( text => 'Hello World' )
    || die Types->reason();
    
is( $text, 'Hello World', 'text auto-stringification' );
is( $$text, 'Hello World', 'explicit text dereference' );
is( $text->text, 'Hello World', 'text() method' );
is( $text->length, 11, 'length is 11' );


#------------------------------------------------------------------------
# now a Template::TT3::Type::List object
#------------------------------------------------------------------------

# first try a list of arguments
my $list = TYPES->create( list => 10, 20, 30 );
ok( $list, 'got list object' );
is( $list->size, 3, 'three items in list' );
is( $list->first, 10, 'first item is 10' );
is( $list->[-1], 30, 'last item is 30' );

# try again with list reference
$list = TYPES->create( list => [ 40, 50] );
ok( $list, 'got second list object' );
is( $list->size, 2, 'two items in list' );
is( $list->first, 40, 'first item is 40' );
is( $list->[-1], 50, 'last item is 50' );


#------------------------------------------------------------------------
# finally a Template::TT3::Type::Hash object
#------------------------------------------------------------------------

# first with a list of named parameters
my $hash = TYPES->create( hash => foo => 10, bar => 20 );
ok( $hash, 'got hash object' );
is( $hash->size, 2, 'two items in hash' );
is( $hash->item('foo'), 10, 'foo item is 10' );
is( $hash->{ bar }, 20, 'bar item is 20' );

# and again with hash ref
$hash = TYPES->create( hash => { foo => 20, bar => 30 } );
ok( $hash, 'got hash object again' );
is( $hash->size, 2, 'still two items in hash' );
is( $hash->item('foo'), 20, 'foo item is 20' );
is( $hash->{ bar }, 30, 'bar item is 30' );


#------------------------------------------------------------------------
# try bad object name
#------------------------------------------------------------------------

ok( ! TYPES->try->create( frobulator => 99 ), 'no frobulator' );
is( TYPES->reason->info, "type not found: frobulator", 'frobulator error' );


#------------------------------------------------------------------------
# now try again with a Template::TT3::Types object
#------------------------------------------------------------------------

my $types = TYPES->new;

$text = $types->create( text => 'Hello World' );
is( $text, 'Hello World', 'got object text' );
is( $text->length, 11, 'got object text length' );

$list = $types->create( list => [ 'Hello', 'World'] );
is( $list->first, 'Hello', 'got object list first' );
is( $list->[-1], 'World', 'got object list last' );


$hash = $types->create( hash => { 'Hello' => 'World' } );
is( $hash->item('Hello'), 'World', 'got object hash item' );
is( $hash->{'Hello'}, 'World', 'got object hash item direct' );


#------------------------------------------------------------------------
# try disabling hash and list, but not text
#------------------------------------------------------------------------

$types = TYPES->new({
    types => {
        list => 0,
        hash => 0,
    },
}) || die TYPES->error;

ok( $types->create( text => 'Hello World' ), 'still got text' );

ok( ! $types->try->create( list => [ 10, 20 ] ), 'no list' );
is( $types->error->info, "type not found: list", 'no list error' );

ok( ! $types->try->create( hash => { foo => 10 } ), 'no hash' );
is( $types->error->info, "type not found: hash", 'no hash error' );


#-----------------------------------------------------------------------
# get the vtables info
#-----------------------------------------------------------------------

my $vtables = TYPES->vtables;

# make sure we got vtables
ok( $vtables->{ text }, 'got text vtable' );
ok( $vtables->{ list }, 'got list vtable' );
ok( $vtables->{ hash }, 'got hash vtable' );
ok( $vtables->{ ARRAY }, 'got ARRAY vtable' );
ok( $vtables->{ HASH }, 'got HASH vtable' );

# and that the vtables contain vmethods
ok( $vtables->{ text }->{ length }, 'got text.length vmethod' );
is( $vtables->{ text }->{ length }->('foo'), 3, 'called text.length vmethod' );
ok( $vtables->{ list }->{ size }, 'got list.size vmethod' );
is( $vtables->{ list }->{ size }->([2,3,5,7]), 4, 'called list.size vmethod' );



__END__

#------------------------------------------------------------------------
# try adding new object type   # (NOTE: we don' have this object yet)
#------------------------------------------------------------------------

use Template::TT3::Template;

$types = Types->new({
    types => {
        template => 'Template::TT3::Template',
    },
}) || die Types->error();

my $template = $types->object( template => { 
    id   => 'test:hello', 
    path => '/hello',
    text => 'Hello World',
}) ||die $types->error();

is( $template->text(), 'Hello World', 'got template text' );





__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
