#============================================================= -*-perl-*-
#
# t/type/hash.t
#
# Test the Template::TT3::Type::Hash module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug  => 'Template::TT3::Type::Hash',
    args   => \@ARGV,
    tests  => 164;

use Template::TT3::Type::Hash qw(HASH Hash);

local $" = ', ';

my ($data, $hash, $copy, $sub);

is( HASH->type, 'Hash', 'Hash type' );
is( ref HASH->methods, 'HASH', 'Hash methods' );

#-----------------------------------------------------------------------
# check HASH constant is defined and hash() subroutine to create hash
#-----------------------------------------------------------------------

is( HASH, 'Template::TT3::Type::Hash', 'got HASH constant' );
$hash = Hash( a => 10 );
is( ref $hash, HASH, 'got Template::TT3::Type::Hash object from Hash()' );


#------------------------------------------------------------------------
# new() class method
#------------------------------------------------------------------------

# list of named params
$hash = HASH->new( a => 1, b => 2 );
ok( $hash, 'created a hash from params' );
is( $hash->{ a }, 1, 'a is 1' );
is( $hash->{ b }, 2, 'b is 2' );

# hash array
$data = { a => 10, b => 20 };
$hash = HASH->new($data);
ok( $hash, 'created a hash from a hashref' );
is( $hash->{ a }, 10, 'a hash is 10' );
is( $hash->{ b }, 20, 'b hash is 20' );

# should be a wrapper around original data 
$data->{ c } = 30;
is( $hash->{ c }, 30, 'c hash is 30' );

# create Hash by copying another Hash
$copy = HASH->new($hash);
ok( $copy, 'created copy of hash' );
is( $copy->{ a }, 10, 'a copy is 10' );
is( $copy->{ b }, 20, 'b copy is 20' );
is( $copy->{ c }, 30, 'c copy is 30' );

$hash->{ d } = 40;
$copy->{ d } = 50;
is( $hash->{ d }, 40, 'd hash is 40' );
is( $copy->{ d }, 50, 'd copy is 50' );


#------------------------------------------------------------------------
# new() object method
#------------------------------------------------------------------------

# list of named params
$copy = $hash->new( pi => 3.14, e => 2.718 );
ok( $copy, 'object new with params list' );
is( $copy->{ pi }, 3.14, 'pi is 3.14' );
is( $copy->{ e }, 2.718, 'e is 2.718' );
is( scalar keys %$copy, 2, 'two keys in copy' );

# hash ref
$copy = $hash->new({ pi => 3.14, e => 2.718 });
ok( $copy, 'object new with hash ref' );
is( $copy->{ pi }, 3.14, 'pi is 3.14 again' );
is( $copy->{ e }, 2.718, 'e is 2.718 again' );
is( scalar keys %$copy, 2, 'two keys in copy again' );

# hash ref
my $copy2 = $hash->new($copy);
ok( $copy2, 'object new with object' );
is( $copy2->{ pi }, 3.14, 'pi is still 3.14' );
is( $copy2->{ e }, 2.718, 'e is still 2.718' );
is( scalar keys %$copy, 2, 'still only two keys in copy' );


#------------------------------------------------------------------------
# clone() method
#------------------------------------------------------------------------

$hash = HASH->new( pi => 3.14, e => 2.718 );
$copy = $hash->clone();

ok( $copy, 'cloned new object' );
is( $copy->{ pi }, 3.14, 'pi is 3.14 in clone' );
is( $copy->{ e }, 2.718, 'e is 2.718 in clone' );
$hash->{ phi } = 1.618;
is( scalar keys %$copy, 2, 'clone has two keys' );
is( scalar keys %$hash, 3, 'hash has three keys' );

# extra argument to clone() as list
$copy = $hash->clone( phi => 1.618 );
ok( $copy, 'cloned new object with list of params' );
is( $copy->{ pi }, 3.14, 'pi is 3.14 in clone again' );
is( $copy->{ e }, 2.718, 'e is 2.718 in clone again' );
is( $copy->{ phi }, 1.618, 'phi is 1.618 in clone' );

# extra argument to clone() as hash ref
$copy = $hash->clone({ phi => 1.618 });
ok( $copy, 'cloned new object with hash ref of params' );
is( $copy->{ pi }, 3.14, 'pi is still 3.14 in clone' );
is( $copy->{ e }, 2.718, 'e is still 2.718 in clone' );
is( $copy->{ phi }, 1.618, 'phi is still 1.618 in clone' );



#------------------------------------------------------------------------
# copy() method
#------------------------------------------------------------------------

$hash = HASH->new( pi => 3.14, e => 2.718 );
$copy = $hash->copy();
ok( $copy, 'copied new object' );
is( $copy->{ pi }, 3.14, 'pi is 3.14 in copy' );
is( $copy->{ e }, 2.718, 'e is 2.718 in copy' );
$hash->{ phi } = 1.618;
is( scalar keys %$copy, 2, 'copy has two keys' );
is( scalar keys %$hash, 3, 'original now has three keys' );

# extra argument to copy() as list
$copy = $hash->copy( phi => 1.618 );
ok( $copy, 'copied new object with list of params' );
is( $copy->{ pi }, 3.14, 'pi is 3.14 in copy again' );
is( $copy->{ e }, 2.718, 'e is 2.718 in copy again' );
is( $copy->{ phi }, 1.618, 'phi is 1.618 in copy' );

# extra argument to copy() as hash ref
$copy = $hash->copy({ phi => 1.618 });
ok( $copy, 'copied new object with hash ref of params' );
is( $copy->{ pi }, 3.14, 'pi is still 3.14 in copy' );
is( $copy->{ e }, 2.718, 'e is still 2.718 in copy' );
is( $copy->{ phi }, 1.618, 'phi is still 1.618 in copy' );


#------------------------------------------------------------------------
# ref() and type() methods
#------------------------------------------------------------------------

$data = { a => 10, b => 20, c => 30 };

is( $hash->ref(), HASH, 'object ref Hash' );
is( HASH->can('ref')->($data), 'HASH', 'data ref HASH' );

is( $hash->type, 'Hash', 'object type Hash' );
is( HASH->can('type')->($data), 'Hash', 'data type Hash' );


#------------------------------------------------------------------------
# hash() method
#------------------------------------------------------------------------

is( $hash, $hash->hash->hash->hash, 'hash() returns the hash' );
is( HASH->can('hash')->($data), $data, 'hash() returns the data' );


#------------------------------------------------------------------------
# list() method
#------------------------------------------------------------------------

my $list = $hash->list;
is( ref $list, 'ARRAY', 'list() returns a list' );
is( $list->[0], $hash, 'list() item is the hash' );
is( HASH->can('list')->($data)->[0], $data, 'list() returns the data' );

$list = HASH->can('list')->($data);
is( ref $list, 'ARRAY', 'list() sub returns a list' );
is( $list->[0], $data, 'list() sub returns the data' );


#------------------------------------------------------------------------
# text() method
#------------------------------------------------------------------------

is( $hash->text, 'e=2.718, phi=1.618, pi=3.14', 
    'default hash text' );

is( $hash->text('='), 'e=2.718, phi=1.618, pi=3.14', 
    'hash text with one delim' );

is( $hash->text('=','&'), 'e=2.718&phi=1.618&pi=3.14', 
    'hash text with two delims' );


#------------------------------------------------------------------------
# size() method
#------------------------------------------------------------------------

is( $hash->size, 3, 'hash size is 3' );


#------------------------------------------------------------------------
# each() method
#------------------------------------------------------------------------

my $each = $hash->each;
is( ref $each, 'ARRAY', 'each() returns a list' );

$copy = { @$each };
is( $copy->{ pi }, 3.14, 'pi is 3.14 in each' );
is( $copy->{ e }, 2.718, 'e is 2.718 in each' );
is( $copy->{ phi }, 1.618, 'phi is 1.618 in each' );


#------------------------------------------------------------------------
# keys() method
#------------------------------------------------------------------------

my $keys = $hash->keys;
is( ref $keys, 'ARRAY', 'keys() returns a list' );

$copy = [ sort @$keys ];
is( $copy->[0], 'e', 'first key is e' );
is( $copy->[1], 'phi', 'second key is phi' );
is( $copy->[2], 'pi', 'third key is pi' );


#------------------------------------------------------------------------
# values() method
#------------------------------------------------------------------------

my $vals = $hash->values;
is( ref $vals, 'ARRAY', 'values() returns a list' );

$copy = [ sort @$vals ];
is( $copy->[0], 1.618, 'first value is phi' );
is( $copy->[1], 2.718, 'second value is e' );
is( $copy->[2], 3.14, 'third key is pi' );


#------------------------------------------------------------------------
# kvhash() method
#------------------------------------------------------------------------

my $kvhash = $hash->kvhash;
is( ref $kvhash, 'ARRAY', 'kvhash() returns a list' );

$copy = [ sort { $a->{value} <=> $b->{value} } @$kvhash ];
is( "$copy->[0]{key}=$copy->[0]{value}", "phi=1.618", 'first kvhash is phi' );
is( "$copy->[1]{key}=$copy->[1]{value}", "e=2.718", 'second kvhash is e' );
is( "$copy->[2]{key}=$copy->[2]{value}", "pi=3.14", 'third kvhash is pi' );


#------------------------------------------------------------------------
# kvlist() method
#------------------------------------------------------------------------

my $kvlist = $hash->kvlist;
is( ref $kvlist, 'ARRAY', 'kvlist() returns a list' );

$copy = [ sort { $a->[1] <=> $b->[1] } @$kvlist ];
is( "$copy->[0][0]=$copy->[0][1]", "phi=1.618", 'first kvlist is phi' );
is( "$copy->[1][0]=$copy->[1][1]", "e=2.718", 'second kvlist is e' );
is( "$copy->[2][0]=$copy->[2][1]", "pi=3.14", 'third kvlist is pi' );


#------------------------------------------------------------------------
# item() method
#------------------------------------------------------------------------

is( $hash->item('pi'), 3.14, 'hash item pi' );
is( $hash->item('phi'), 1.618, 'hash item phi' );
is( $hash->item('e'), 2.718, 'hash item e' );


#------------------------------------------------------------------------
# exists() and defined() methods
#------------------------------------------------------------------------

ok( $hash->exists('pi'), 'hash item pi exists' );
ok( ! $hash->defined('g'), 'hash item g is not defined' );
ok( ! $hash->exists('g'), 'hash item g does not exist' );

$hash->{ g } = undef;
ok( ! $hash->defined('g'), 'hash item g is still not defined' );
ok( $hash->exists('g'), 'hash item g now exists' );

$hash->{ g } = 0.577;
ok( $hash->defined('g'), 'hash item g is now defined' );
ok( $hash->exists('g'), 'hash item g still exists' );



#------------------------------------------------------------------------
# sort() and nsort() methods
#------------------------------------------------------------------------

$hash->{ ten } = '10';

my $sorted = $hash->sort;
is( ref $sorted, 'ARRAY', 'sort returns an array' );
is( join(', ', @$sorted), 'g, phi, ten, e, pi', 'sorted alphabetically' );

$sorted = $hash->nsort;
is( ref $sorted, 'ARRAY', 'nsort returns an array' );
is( join(', ', @$sorted), 'g, phi, e, pi, ten', 'sorted numerically' );


#------------------------------------------------------------------------
# hash_import() method - we can't call it import() because that messes
# with Exporter!
#------------------------------------------------------------------------

$hash->hash_import( x => 100 );
is( $hash->{ x }, 100, 'x is 100' );
is( $hash->size(), 6, 'size is 6' );

$hash->hash_import({ y => 200 });
is( $hash->{ y }, 200, 'y is 200' );
is( $hash->size(), 7, 'size is 7' );


#------------------------------------------------------------------------
# delete() method
#------------------------------------------------------------------------

is( $hash->delete('x'), 100, 'deleted x' );
is( $hash->delete('y'), 200, 'deleted y' );
is( $hash->size(), 5, 'size is 5' );




#========================================================================
# The following test various methods by calling them as plain subroutines,
# passing a hash reference as the first argument to masquerade as a Hash
# object.
#========================================================================


# subroutine to fetch and call hash virtual method for us
sub hvm {
    my ($vmeth, @args) = @_;
    my $method = HASH->can($vmeth) || return undef;    
#    my $method = HASH->method($vmeth) || return undef;    
    &$method(@args);
}

ok( ! defined hvm( nonsuch => 'hello' ), 'undefined handler' );

$hash = {
    foo => 'The foo item',
    bar => 'bar item',
    baz => 'baz item',
    1   => 'number 1',
    2   => 'number 2',
    10  => 'number 10',
};


#------------------------------------------------------------------------
# ref, type
#------------------------------------------------------------------------

is( hvm( ref => $hash), 'HASH', 'ref HASH' );
is( hvm( type => $hash), 'Hash', 'HASH type' );


#------------------------------------------------------------------------
# text, item, hash, list, copy
#------------------------------------------------------------------------

is( hvm( text => $hash ), 
    '1=number 1, 10=number 10, 2=number 2, '
  . 'bar=bar item, baz=baz item, foo=The foo item',
    'hash.text' );

is( hvm( text => $hash, ': ' ), 
    '1: number 1, 10: number 10, 2: number 2, '
  . 'bar: bar item, baz: baz item, foo: The foo item',
    "hash.text(': ')" );

is( hvm( text => $hash, ': ', "\n" ), 
    "1: number 1\n10: number 10\n2: number 2\n"
  . "bar: bar item\nbaz: baz item\nfoo: The foo item",
    "hash.text(': ', \"\\n\")" );

is( hvm( item => $hash, 'foo'), 'The foo item', 'item' );
is( hvm( hash => $hash), $hash, 'same hash' );

$list = hvm( list => $hash );
ok( $list, 'got a list' );
is( scalar @$list, 1, 'contains 1 item' );
is( ref $list->[0], 'HASH', "it's a hash" );
is( $list->[0]->{ foo }, 'The foo item', "it's the right hash" );

$copy = hvm( copy => $hash );
is( ref $hash, 'HASH', 'got a hash' );
ok( $hash != $copy, 'not the same hash' );
is( scalar keys %$hash, 6, 'contains 6 items' );
is( $hash->{ foo }, 'The foo item', "contains foo" );



#------------------------------------------------------------------------
# each, keys, values, keyvalues
#------------------------------------------------------------------------

$list = hvm( each => $hash );
ok( $list, 'got a list of each' );
is( scalar @$list, 12, 'contains 12 item' );
$list = [ sort @$list ];
is( $list->[0], '1', "got the right each 1" );
is( $list->[3], 'The foo item', "got the right each 2" );
is( $list->[4], 'bar', "got the right each 3" );

$list = hvm( keys => $hash );
ok( $list, 'got a list of keys' );
is( scalar @$list, 6, 'contains 6 item' );
$list = [ sort @$list ];
is( $list->[0], '1', "got the right keys" );
is( $list->[3], 'bar', "got the right keys" );

$list = hvm( values => $hash );
ok( $list, 'got a list of values' );
is( scalar @$list, 6, 'contains 6 item' );
$list = [ sort @$list ];
is( $list->[0], 'The foo item', "got the right values 1" );
is( $list->[3], 'number 1', "got the right values 2" );

$list = hvm( kvhash => $hash );
ok( $list, 'got a list of keyvalues' );
is( scalar @$list, 6, 'contains 6 items' );
is( ref $list->[0], 'HASH', "got a list of hashes" );
ok( defined $list->[0]->{ key }, 'key is defined' );


#------------------------------------------------------------------------
# exists, defined
#------------------------------------------------------------------------

ok(   hvm( exists  => $hash, 'foo' ), 'foo exists' );
ok(   hvm( defined => $hash, 'foo' ), 'foo is defined' );
ok( ! hvm( exists  => $hash, 'nothing' ), 'nothing does not exist' );
ok( ! hvm( defined => $hash, 'nothing' ), 'nothing is not defined' );


#------------------------------------------------------------------------
# sort, nsort
#------------------------------------------------------------------------

$keys = hvm( sort => $hash );
is( scalar @$keys, 6, '6 keys' );
is( $keys->[0], 'bar', 'bar is first' );
is( $keys->[1], 'baz', 'baz is second' );
is( $keys->[2], '1', '1 is third' );
is( $keys->[3], '10', '10 is fourth' );
is( $keys->[4], '2', '2 is fifth' );
is( $keys->[5], 'foo', '2 is sixth' );


$hash = {
    one     => 1,
    eleven  => 11,
    ten     => 10,
    two     => 2,
    three   => 3,
    twenty  => 20,
    zero    => 0,
};

$keys = hvm( nsort => $hash );
is( scalar @$keys, 7, '7 keys' );
is( $keys->[0], 'zero', 'zero is first' );
is( $keys->[1], 'one', 'one is second' );
is( $keys->[2], 'two', 'two is third' );
is( $keys->[3], 'three', 'three is fourth' );
is( $keys->[4], 'ten', 'ten is fifth' );
is( $keys->[5], 'eleven', 'eleven is sixth' );
is( $keys->[6], 'twenty', 'twenty is seventh' );



#------------------------------------------------------------------------
# import
#------------------------------------------------------------------------

$hash = {
    first  => 1,
    second => 2,
    third  => 10,
    fifth  => 20,
};

hvm( hash_import => $hash, {
    fourth => 15,
    sixth  => 25,
});

$keys = hvm( nsort => $hash );
is( join(', ', @$keys), 'first, second, third, fourth, fifth, sixth', 'nsorted' );


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
