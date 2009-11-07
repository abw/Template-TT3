#============================================================= -*-perl-*-
#
# t/type/source.t
#
# Test the Template::TT3::Type::Source module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug  => 'Template::TT3::Type::Source',
    args   => \@ARGV,
    tests  => 49;

use Template::TT3::Type::Source 'SOURCE Source';
use constant SourceType => 'Template::TT3::Type::Source';

pass('loaded Template::TT3::Type::Source');

my ($src, $copy, $string, $list, $hash);


#-----------------------------------------------------------------------
# check SOURCE constant is defined and Source() constructor subroutine
#-----------------------------------------------------------------------

is( SOURCE, SourceType, 'got SOURCE constant' );

$src = Source('Hello World');
is( ref $src, SOURCE, 'got Template::TT3::Type::Source object from Source()' );
is( $src, 'Hello World', 'text from Source() is Hello World' );
is( $src->type, 'Source', 'source type is Source' );


#-----------------------------------------------------------------------
# scanning/parsing/debugging methods
#-----------------------------------------------------------------------

my $source = Source(<<EOF);
foo bar
baz boz
ding dong
bing bong
dilly dally
silly sally
sing song
this is a very long line which we will use to test the source extraction capability, it just goes on and on, you could go away and have a cup of tea and you'd still be hearing it
wing wong
pee poo
woo hoo
EOF

# at start
whereabouts($source) if $DEBUG;
is($source->position, 0, 'at start of text' );
is($source->line, 1, 'on first line' );
is($source->column, 1, 'at first column' );

# scan: foo
ok( $$source =~ /\w+\s/g ? 1 : 0, 'matched first word' );
whereabouts($source) if $DEBUG;
is($source->position, 4, 'at start of next word' );
is($source->line, 1, 'still on first line' );
is($source->column, 5, 'at column 5' );

# scan: bar baz boz ding
ok( $$source =~ /\G(\w+\s){4}/gs ? 1 : 0, 'matched four more words' );
whereabouts($source) if $DEBUG;
is($source->position, 21, 'at start of fifth word' );
is($source->line, 3, 'now on third line' );
is($source->column, 6, 'at column 6' );

# scan: dong through to silly, inclusive
ok( $$source =~ /\G(\w+\s){6}/gs ? 1 : 0, 'matched six more words' );
whereabouts($source) if $DEBUG;
is($source->position, 54, 'at start of twelth word' );
is($source->line, 6, 'now on sixth line' );
is($source->column, 7, 'at column 7' );

# scan: sally
ok( $$source =~ /\G(\w+\s)/gs ? 1 : 0, 'matched another word' );
whereabouts($source) if $DEBUG;
is($source->position, 60, 'at start of next line' );
is($source->line, 7, 'now on seventh line' );
is($source->column, 1, 'at column one again' );
is( $source->location, 
"at line 7 column 1:
  sing song
  ^", 'showed extract');

# scan past 'is '
ok( $$source =~ /\G.*? is /gs ? 1 : 0, 'matched to next line' );
whereabouts($source) if $DEBUG;
is($source->position, 78, 'just past "is"' );
is($source->line, 8, 'now on eighth line' );
is($source->column, 9, 'at column nine' );
is( $source->location, 
"at line 8 column 9:
  this is a very long line which we will use to test the source extract...
          ^", 'truncated end of long extract');

# should be able to specify short line length
is( $source->location(line_length => 50), 
"at line 8 column 9:
  this is a very long line which we will use to t...
          ^", 'truncated end with short line length');

# and a different ... symbol
is( $source->location(line_length => 50, trimmed => '[more]'), 
"at line 8 column 9:
  this is a very long line which we will use t[more]
          ^", 'truncated end with short line length');

# scan past 'test '
ok( $$source =~ /\G.*? test /gs ? 1 : 0, 'matched to middle of long line' );
whereabouts($source) if $DEBUG;
is($source->position, 121, 'just past "test"' );
is($source->line, 8, 'still on eighth line' );
is($source->column, 52, 'at column 52' );
is( $source->location, 
"at line 8 column 52:
  this is a very long line which we will use to test the source extract...
                                                     ^", 'extract in middle of long line');

ok( $$source =~ /\Gt/gs ? 1 : 0, 'matched next letter t' );
is( $source->location, 
"at line 8 column 53:
  this is a very long line which we will use to test the source extract...
                                                      ^", 'extract still got space');
ok( $$source =~ /\Gh/gs ? 1 : 0, 'matched next letter h' );
is( $source->location, 
"at line 8 column 54:
  ... is a very long line which we will use to test the source extracti...
                                                      ^", 'extract shifted one');

ok( $$source =~ /\Ge /gs ? 1 : 0, 'matched next letter e' );
is( $source->location, 
"at line 8 column 56:
  ...s a very long line which we will use to test the source extraction...
                                                      ^", 'extract shifted one more');

ok( $$source =~ /\G.*you'/gs ? 1 : 0, 'matched past you' );
is( $source->location, 
"at line 8 column 158:
  ... you could go away and have a cup of tea and you'd still be hearin...
                                                      ^", 'extract shifted to near end');

ok( $$source =~ /\Gd/gs ? 1 : 0, 'matched past letter d' );
is( $source->location, 
"at line 8 column 159:
  ...you could go away and have a cup of tea and you'd still be hearing it
                                                      ^", 'extract shifted to inside end');

ok( $$source =~ /\G still be hearing /gs ? 1 : 0, 'matched to last word' );
is( $source->location,
"at line 8 column 177:
  ...you could go away and have a cup of tea and you'd still be hearing it
                                                                        ^", 'extract shifted to last word');


sub whereabouts {
    my $text = shift;
    my $where = $text->whereabouts;
    print "at line $where->{ line } column $where->{ column }:\n  $where->{ extract }\n",
        '  ', ' ' x $where->{ offset }, "^\n";
    print " [", '1234567890' x 7, "12]\n";
}


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
