#============================================================= -*-perl-*-
#
# t/type/text.t
#
# Test the Template::TT3::Type::Text module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug  => 'Template::TT3::Type::Text',
    args   => \@ARGV,
    tests  => 166;

use Template::TT3::Type::Text qw( TEXT Text );
pass('loaded Template::TT3::Type::Text');

use constant TextType => 'Template::TT3::Type::Text';

my ($text, $copy, $string, $list, $hash);


#-----------------------------------------------------------------------
# check TEXT constant is defined and Text() subroutine to create text
#-----------------------------------------------------------------------

is( TEXT, TextType, 'got TEXT constant' );

$text = Text('Hello World');
is( ref $text, TextType, 'got Template::TT3::Type::Text object from Text()' );
is( $text, 'Hello World', 'text from Text() is Hello World' );
is( $text->type, 'Text', 'text type is Text' );


#------------------------------------------------------------------------
# method() and methods()
#------------------------------------------------------------------------

is( ref TEXT->methods(), 'HASH', 'got text methods' );
is( ref TEXT->method('new'), 'CODE', 'got new() method' );
is( TEXT->method('length'), \&Template::TT3::Type::Text::length, 'got length() method' );


#-----------------------------------------------------------------------
# basic new() constructor
#-----------------------------------------------------------------------

$text = Text->new('Hello World');
is( ref $text, 'Template::TT3::Type::Text', 'got Template::TT3::Type::Text object' );
is( $text, 'Hello World', 'text is Hello World' );

$copy = Text->new($text);
is( ref $copy, 'Template::TT3::Type::Text', 'got Template::TT3::Type::Text copy object' );
is( $copy, 'Hello World', 'copy text is Hello World' );

$text = TEXT->new('Hello World');
is( $$text, 'Hello World', 'set text' );

$text = TEXT->new('Hello', 'World');
is( $$text, 'HelloWorld', 'set text args' );

$string = 'Hello again';
$text = TEXT->new(\$string);
is( $$text, 'Hello again', 'set text by ref' );

$copy = TEXT->new($$text);
is( $$copy, 'Hello again', 'set text by copy' );
$$text .= ', how nice to see you';
is( $$text, 'Hello again, how nice to see you', 'text changed' );
is( $$copy, 'Hello again', 'copy unchanged' );

$copy = TEXT->new($text, ', you look well');
is( $$copy, 'Hello again, how nice to see you, you look well',
    'extreme pleasantries' );

#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

$copy->init('New Text');
is( $$copy, 'New Text', 'init() new text' );


#------------------------------------------------------------------------
# copy()
#------------------------------------------------------------------------

$text = TEXT->new('a new message');
$copy = $text->copy();
is( $$copy, 'a new message', 'cloned text' );

$copy = $text->copy(' with some more');
is( $$copy, 'a new message with some more', 'cloned text with args' );

# TODO: text.item - not sure what .item is going to do in TT3...

#-----------------------------------------------------------------------
# text()
#-----------------------------------------------------------------------

$text = Text('Hello World');
$copy = $text->text();
is( $text, $copy, 'text.text returns self' );


#-----------------------------------------------------------------------
# list()
#-----------------------------------------------------------------------

$list = $text->list();
is( ref $list, 'ARRAY', 'got list from text.list' );
is( scalar @$list, 1, 'one item in list' );
is( $list->[0], $text, 'got text as first item' );


#-----------------------------------------------------------------------
# hash()
#-----------------------------------------------------------------------

$text = TEXT->new('hash text');
$hash = $text->hash();
is( ref $hash, 'HASH', 'got hash' );
is( scalar keys %$hash, 1, 'one text item in hash' );
is( $hash->{ text }, 'hash text', 'got hash text' );

$text = TEXT->new('hash name');
$hash = $text->hash('name');
is( ref $hash, 'HASH', 'got hash' );
is( scalar keys %$hash, 1, 'one name item in hash' );
is( $hash->{ name }, 'hash name', 'got hash name' );

$text = TEXT->new('hash values');
$hash = $text->hash('name', age => 35, beard => 'goatee');
is( ref $hash, 'HASH', 'got hash values' );
is( scalar keys %$hash, 3, 'three items in hash' );
is( $hash->{ name }, 'hash values', 'got hash values' );
is( $hash->{ age }, '35', 'got age' );
is( $hash->{ beard }, 'goatee', 'got a goatee beard' );

$hash = $text->hash('item');
is( ref $hash, 'HASH', 'got hash from text.hash with key name' );
is( $hash->{ item }, $text, 'got text from hash as item key' );


#------------------------------------------------------------------------
# defined()
#------------------------------------------------------------------------

ok( $text->defined(), 'text is defined' );

$text = TEXT->new('');
ok( $text->defined(), 'empty text is still defined' );
is( $$text, '', 'empty text' );

$text = TEXT->new();
ok( ! $text->defined(), 'no text is not defined' );
ok( ! defined $$text, 'no text specified' );

$text = TEXT->new(undef);
ok( ! $text->defined(), 'undef text is not defined' );
ok( ! defined $$text, 'undefined text' );

$text = TEXT->new(undef, undef);
ok( ! $text->defined(), 'multi-undef text is not defined' );
ok( ! defined $$text, 'multi-undefined text' );

# make sure we can append text onto an undefined value without
# any problems or warnings
is( $text->append('wiz'), 'wiz', 'appended wiz onto undef' );


#-----------------------------------------------------------------------
# size() and length()
#-----------------------------------------------------------------------

# TODO: there's an idea in the back of my head that text.size should return 0
# to make it easier to distinguish from lists... not sure about that...

$text = TEXT->new('Hello World');
is( $text->size, 1, 'text.size is one' );
is( $text->length(), 11, 'text.length says eleven characters' );


#-----------------------------------------------------------------------
# equals() and compare()
#-----------------------------------------------------------------------

my $a = Text('Hello World');
my $b = $a->copy();
my $c = Text('Hello Badger');

ok( $a->equals($b), 'a equals b' );
ok( ! $a->equals($c), 'a does not equal c' );
is( $a->compare($b), 0, 'a compares exactly to b' );
ok( $a->compare($c) > 0, 'a compares after c' );
ok( $c->compare($a) < 0, 'c compares before a' );
ok( $a->after($c), 'a comes after c' );
ok( $c->before($a), 'c comes before a' );


# try again with basic strings
ok( $a->equals('Hello World'), 'a equals Hello World' );
ok( ! $a->equals('Hello Badger'), 'a does not equal Hello Badger' );
is( $a->compare('Hello World'), 0, 'a compares exactly to Hello World' );
ok( $a->compare('Hello Badger') > 0, 'a compares after Hello Badger' );
ok( $c->compare('Hello World') < 0, 'Hello Badger compares before Hello World' );
ok( $a->after('Hello Badger'), 'a comes after Hello Badger' );
ok( $c->before('Hello World'), 'Hello Badger comes before Hello World' );

# and again with string refs
ok( $a->equals(\'Hello World'), 'a equals Hello World ref' );
ok( ! $a->equals(\'Hello Badger'), 'a does not equal Hello Badger ref' );
is( $a->compare(\'Hello World'), 0, 'a compares exactly to Hello World ref' );
ok( $a->compare(\'Hello Badger') > 0, 'a compares after Hello Badger ref' );
ok( $c->compare(\'Hello World') < 0, 'Hello Badger compares before Hello World ref' );
ok( $a->after(\'Hello Badger'), 'a comes after Hello Badger ref' );
ok( $c->before(\'Hello World'), 'Hello Badger comes before Hello World ref' );

# test the operators overload OK

my $foo = TEXT->new('foo');
my $bar = TEXT->new('bar');
my $baz = TEXT->new('baz');

is( $baz->compare($foo), -1, 'baz comes before foo' );
is( $baz->compare($baz), 0, 'baz is baz' );
is( $baz->compare($bar), 1, 'baz comes after bar' );

is( $baz cmp $foo, -1, 'baz cmp foo' );
is( $baz lt $foo, 1, 'baz lt foo' );
is( $baz < $foo, 1, 'baz < foo' );
is( $foo > $baz, 1, 'foo > baz' );


#------------------------------------------------------------------------
# append()
#------------------------------------------------------------------------

$text = TEXT->new('foo ');
is(  $text->append('bar'), 'foo bar', 'appended bar' );
is(  $text->text(), 'foo ', 'still foo' );


#------------------------------------------------------------------------
# some simple accessor tests
#------------------------------------------------------------------------

$text = TEXT->new('Hello World');
is( $text->text(), 'Hello World', 'Hello World by method' );
is( $text->upper(), 'HELLO WORLD', 'HELLO WORLD upper' );
is( $text->lower(), 'hello world', 'hello world lower' );
is( $text->text(), 'Hello World', 'Hello World unchanged' );

my $upper = $text->can('upper');
my $source = 'Goodbye Cruel World';
is( &$upper(\$source), 'GOODBYE CRUEL WORLD', 'upper sub call' );




#-----------------------------------------------------------------------
# test virtual methods directly
#-----------------------------------------------------------------------

sub tvm {
    my ($vmeth, @args) = @_;
    my $handler = Template::TT3::Type::Text->can($vmeth) || return undef;
    &$handler(@args);
}

ok( ! defined tvm( nonsuch => 'hello' ), 'undefined handler' );

$text = 'The foo string';


#------------------------------------------------------------------------
# ref, type
#------------------------------------------------------------------------

is( tvm( ref  => $text ), '', 'non-ref text' );
is( tvm( type => $text ), 'Text', ' type' );


#------------------------------------------------------------------------
# text, item, list, hash, copy
#------------------------------------------------------------------------

is( tvm( text => $text ), $text, 'text.text' );
is( tvm( item => $text ), $text, 'text.item' );
is( tvm( copy => $text ), $text, 'text.copy' );

$list = tvm( list => $text );
ok( $list, 'text.list returned something' );
is( ref $list, 'ARRAY', 'text.list returned a list' );
is( scalar @$list, 1, 'containing 1 item list' );
is( $list->[0], $text, 'item 0 is $text' );

$hash = tvm( hash => $text );
ok( $hash, 'text.hash returned something' );
is( ref $hash, 'HASH', 'text.hash returned a hash' );
is( $hash->{ text }, $text, 'item is $text' );


#------------------------------------------------------------------------
# append, prepend
#------------------------------------------------------------------------

is( tvm( append => $text, ' more foo' ), 
    'The foo string more foo', 'single append' );

is( tvm( append => $text, ' more foo', ' even more foo' ), 
    'The foo string more foo even more foo', 'multiple append' );

is( tvm( prepend => $text, 'This is ' ), 
    'This is The foo string', 'single prepend' );

is( tvm( prepend => $text, 'And this', ' ', 'still is', ' ' ), 
    'And this still is The foo string', 'multiple prepend' );


#------------------------------------------------------------------------
# size, length, equals
#------------------------------------------------------------------------

is( tvm( size  => $text ), 1, 'text.size is 1' );
is( tvm( length => $text ), length $text, 
    'text.length is ' . length $text );
ok( tvm( equals => $text, $text ), 'equals' );


#------------------------------------------------------------------------
# centre, center, left, right, format
#------------------------------------------------------------------------

is( tvm( centre => 'ping', 10 ), '   ping   ', 'ping centred' );
is( tvm( center => 'ping', 10 ), '   ping   ', 'ping centered' );
is( tvm( left => 'pong', 10 ), 'pong      ', 'pong left' );
is( tvm( right => 'pong', 10 ), '      pong', 'pong right' );
is( tvm( format => 'foo', '<img src="%s.png">' ),
    '<img src="foo.png">', 'simple format' );
is( tvm( format => 'foo', '<img src="%s.%s">', 'png' ),
    '<img src="foo.png">', 'format with args' );


#------------------------------------------------------------------------
# upper, lower, capital, capitals
#------------------------------------------------------------------------

is( tvm( upper => $text ), 'THE FOO STRING', 'upper' );
is( tvm( lower => $text ), 'the foo string', 'lower 1' );
is( tvm( lower => 'UP and DOWN' ), 'up and down', 'lower 2' );
is( tvm( capital => 'the foo bar' ), 'The foo bar', 'capital 1' );
is( tvm( capital => '... the foo bar' ), '... The foo bar', 'capital 2' );
is( tvm( capitals => $text ), 'The Foo String', 'capitals 1' );
is( tvm( capitals => '... 10 20 once upon a time ...' ),
	 '... 10 20 Once Upon A Time ...', 'capitals 2' );


#------------------------------------------------------------------------
# chop, chomp, trim, collapse, truncate
#------------------------------------------------------------------------

is( tvm( chop => "foo bar\n" ), 'foo bar', 'chop 1' );
is( tvm( chop => "foo bars" ), 'foo bar', 'chop 2' );
is( tvm( chomp => "foo bar\n" ), 'foo bar', 'chomp 1' );
is( tvm( chomp => "foo bars" ), 'foo bars', 'chomp 2' );
is( tvm( trim => "  \n  foo bars  \n\n " ), 'foo bars', 'trim 1' );
is( tvm( trim => "  \n  foo \n bars  \n\n " ), "foo \n bars", 'trim 2' );
is( tvm( collapse => "  \n  foo bars  \n\n " ), 'foo bars', 'collapse 1' );
is( tvm( collapse => "  \n  foo \n bars  \n\n " ), "foo bars", 'collapse 2' );
is( tvm( truncate => $text, 20 ), "The foo string", 'truncate 0' );
is( tvm( truncate => $text, 10 ), "The foo st", 'truncate 1' );
is( tvm( truncate => $text, 10, '...' ), "The foo...", 'truncate 2' );


#------------------------------------------------------------------------
# chunk, repeat, remove, replace, match, search, split
#------------------------------------------------------------------------

$text = 'TheCatSatTheMat';
$list = tvm( chunk => $text, 3 );
ok( $list && ref $list eq 'ARRAY', 'text.chunk(3) returned a list' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[0], 'The', 'The' );
is( $list->[1], 'Cat', 'Cat' );
is( $list->[2], 'Sat', 'Sat' );
is( $list->[3], 'The', 'The' );
is( $list->[4], 'Mat', 'Mat' );


$text = 'TheCatSatonTheMat';
$list = tvm( chunk => $text, 3 );
ok( $list && ref $list eq 'ARRAY', 'text.chunk(3) returned a list' );
is( scalar @$list, 6, 'list has 5 items' );
is( $list->[0], 'The', 'The' );
is( $list->[1], 'Cat', 'Cat' );
is( $list->[2], 'Sat', 'Sat' );
is( $list->[3], 'onT', 'onT' );
is( $list->[4], 'heM', 'heM' );
is( $list->[5], 'at', 'at' );

$text = 'TheCatSatTheMat';
$list = tvm( chunk => $text, -3 );
ok( $list && ref $list eq 'ARRAY', 'text.chunk(-3) returned a list' );
is( scalar @$list, 5, 'list has 5 items' );
is( $list->[0], 'The', 'The' );
is( $list->[1], 'Cat', 'Cat' );
is( $list->[2], 'Sat', 'Sat' );
is( $list->[3], 'The', 'The' );
is( $list->[4], 'Mat', 'Mat' );

$text = 'TheCatSatonTheMat';
$list = tvm( chunk => $text, -3 );
ok( $list && ref $list eq 'ARRAY', 'text.chunk(-3) returned a list' );
is( scalar @$list, 6, 'list has 6 items' );
is( $list->[0], 'Th', 'Th' );
is( $list->[1], 'eCa', 'eCa' );
is( $list->[2], 'tSa', 'tSa' );
is( $list->[3], 'ton', 'ton' );
is( $list->[4], 'The', 'The' );
is( $list->[5], 'Mat', 'Mat' );

$text = '1234567824683579';
$list = tvm( chunk => $text, 4 );
ok( $list && ref $list eq 'ARRAY', 'text.chunk(4) returned a list' );
is( scalar @$list, 4, 'list has 4 items' );
is( $list->[0], '1234', 'got 1234' );
is( $list->[1], '5678', 'got 5678' );
is( $list->[2], '2468', 'got 2468' );
is( $list->[3], '3579', 'got 3579' );


#-----------------------------------------------------------------------
# TODO: 
#    # comparison and pattern matching methods
#    'match'    => \&match,
#    'search'   => \&search,
#    'replace'  => \&replace,
#    'remove'   => \&remove,
#-----------------------------------------------------------------------

__END__

$text = 'The foo string';
is( tvm( repeat  => $text, 2 ), 'The foo stringThe foo string', 'repeat' );
is( tvm( remove  => $text, '\s+foo' ), 'The string', 'remove' );
is( tvm( replace => $text, '\s+foo', ' bar' ), 'The bar string', 'replace' );
ok( tvm( match => $text, 'foo'), 'match 1' );
my $matches = tvm( match => $text, 'o');
is( scalar @$matches, 2, 'match 2' );

ok( tvm( search => $text, 'foo'), 'search 1' );
my $searches = tvm( search => $text, 'o');
is( scalar @$searches, 2, 'search 2' );


my $splits = tvm( split => $text );
is( scalar @$splits, 3, 'split 1' );
is( $splits->[0], 'The', 'The' );
is( $splits->[1], 'foo', 'foo' );
is( $splits->[2], 'string', 'string' );

$splits = tvm( split => $text, '\s+foo\s+' );
is( scalar @$splits, 2, 'split 2' );
is( $splits->[0], 'The', 'The' );
is( $splits->[1], 'string', 'string' );




__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
