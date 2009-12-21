#============================================================= -*-perl-*-
#
# t/views/tree_sexpr.t
#
# Tests for the Template::TT3::View::Tree::Sexpr module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib   => '../../lib',
    Debug => ':dump :debug';

use Template::TT3::Test 
    tests  => 15,
    debug  => 'Template::TT3::View::Tree::Vars',
    args   => \@ARGV;

use Template::TT3::Elements;
use constant ELEMS => 'Template::TT3::Elements';


#-----------------------------------------------------------------------
# terminal elements: text, number, word, keyword, file
#-----------------------------------------------------------------------

my $text = ELEMS->create( text => 'Hello World' );
is( 
    $text->sexpr,
    '<text:Hello World>',
    'text'
);

my $num = ELEMS->create( number => 42 );
is( 
    $num->sexpr,
    '<number:42>',
    'number'
);

my $word = ELEMS->create( word => 'foo' );
is( 
    $word->sexpr,
    '<word:foo>',
    'word'
);

my $keyword = ELEMS->create( keyword => 'if' );
is( 
    $keyword->sexpr,
    '<keyword:if>',
    'keyword'
);

my $file = ELEMS->create( filename => 'foo.txt' );
is( 
    $file->sexpr,
    '<filename:foo.txt>',
    'filename'
);


#-----------------------------------------------------------------------
# block
#-----------------------------------------------------------------------

my $block = ELEMS->create( block => undef, undef, [$text,$num] );
is( 
    $block->sexpr,
    "<block:\n  <text:Hello World>\n  <number:42>\n>",
    'block'
);


#-----------------------------------------------------------------------
# squote and dquote
#-----------------------------------------------------------------------

my $squote = ELEMS->create( squote => "'hello world'" );
is( 
    $squote->sexpr,
    "<squote:'hello world'>",
    'squote'
);

my $dquote = ELEMS->create( dquote => '"hello world"' );
is( 
    $dquote->sexpr,
    '<dquote:"hello world">',
    'token dquote'
);

$dquote = ELEMS->create( dquote => undef, 0, '"hello world"' );
is( 
    $dquote->sexpr,
    '<dquote:"hello world">',
    'static dquote'
);

$dquote = ELEMS->create( dquote => undef, 0, undef, $block );
is( 
    $dquote->sexpr,
    "<dquote:\n  <block:\n    <text:Hello World>\n    <number:42>\n  >\n>",
    'dynamic dquote'
);



#-----------------------------------------------------------------------
# variables, function application, dotops, etc.
#-----------------------------------------------------------------------

my $var = ELEMS->create( variable => 'n' );
is( 
    $var->sexpr,
    "<variable:n>",
    'simple variable'
);

my $apply = ELEMS->create( var_apply => 'n()', 0, $var );
is( 
    $apply->sexpr,
    "<apply:\n  <variable:n>\n  <args:>\n>",
    'variable application'
);

$apply = ELEMS->create( var_apply => 'n()', 0, $var, undef, $block );
is( 
    $apply->sexpr,
    "<apply:\n  <variable:n>\n  <args:\n    <text:Hello World>\n    <number:42>\n  >\n>",
    'variable application with args'
);

my $dotop = ELEMS->create( op_dot => 'TEST', 0, $var, $word );
is( 
    $dotop->sexpr,
    "<dot:\n  <variable:n>\n  <word:foo>\n  <args:>\n>",
    'dotop'
);


#-----------------------------------------------------------------------
# prefix and postfix unary operators
#-----------------------------------------------------------------------

use Template::TT3::Element::Operator::Number;

my $preinc = ELEMS->create( num_pre_inc => '++', 0, undef, $var );

is( 
    $preinc->sexpr,
    "<prefix:<op:++><variable:n>>",
    'preinc'
);

exit;

my $postinc = ELEMS->create( num_post_inc => '++', 0, $var );
is( 
    $postinc->sexpr,
    "<postfix:<op:++><variable:n>>",
    'postinc'
);


#-----------------------------------------------------------------------
# binary operators
#-----------------------------------------------------------------------

my $a   = ELEMS->create( number => 400 );
my $b   = ELEMS->create( number =>  20 );
my $add = ELEMS->create( num_add => '+', 0, $a, $b );
is( 
    $add->sexpr,
    "<binary:<op:+><number:400><number:20>>",
    'binary add'
);


