#============================================================= -*-perl-*-
#
# t/modules/parser.t
#
# Test the Template::TT3::Parser module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 1,
    debug => 'Template::TT3::Parser',   # this doesn't work :-(
    args  => \@ARGV;

use Template::TT3::Parser;
use Template::TT3::Generator;
use constant {
    PARSER => 'Template::TT3::Parser',
    GENERATOR => 'Template::TT3::Generator',
};

my $parser = PARSER->new(
    keywords => {
        fill => 'FILL',
        with => 'WITH',
    },
    namespaces => {
        qq => 'QQ',
    },
);
ok( $parser, 'created parser' );

my $generator = GENERATOR->new;
ok( $generator, 'created generator' );


#-----------------------------------------------------------------------
# basic variables
#-----------------------------------------------------------------------

parse(
    'a.b.c.d', 
    'var:a.b.c.d'
);
parse(
    'a(1).b(2,3).c(4).d(5,e(6))',
    'var:a(num:1).b(num:2, num:3).c(num:4).d(num:5, var:e(num:6))'
);
parse(
    "foo(a(101),b).bar(c,\nd # hello\n e) # a comment\n.baz",
    'var:foo(var:a(num:101), var:b).bar(var:c, var:d, var:e).baz'
);


#-----------------------------------------------------------------------
# double quotes
#-----------------------------------------------------------------------

parse('"foo"', 'foo');
parse('"foo\"bar"', 'foo"bar');
parse(q{"foo\bar\\baz\\\bam"}, 'foo\bar\baz\\bam');    # hard to tell
parse('"foo\nbar\tbaz\\bam\"END"', "foo\nbar\tbaz\\bam\"END");
parse('"foo $bar ${baz.bam}"', '"foo $bar ${baz.bam}"');


#-----------------------------------------------------------------------
# namespace quotes
#-----------------------------------------------------------------------

parse("q:(some text)", 'some text');
parse("q:[more text]", 'more text');
parse("q:(blah text)", 'blah text');
parse("q:<foop text>", 'foop text');
parse("q:{doop text}", 'doop text');
parse(q{'Tam O\'Shanter'}, q{Tam O'Shanter});
parse(q{q:'Tam O\'Shanter'}, q{Tam O'Shanter});
parse(q{q:<Tam O'Shanter>}, q{Tam O'Shanter});
parse(q{q:<10 \> 9>}, q{10 > 9});
parse(q{q:[a\\\\b\\]\c\\\\]});

# TODO: BROKEN - not unescaping \\
parse(<<'EOF', 'a\\b\\\\c\\\\\\d\\\\\\\\e!!!!');
q:<a\b\\c\\\d\\\\e>
EOF

#parse("fill x");
parse('var:x', 'var:x');
parse('var:');


parse(q{'a\b\\c\\\d\'e\\\\f\'g'}, q{a\b\c\\d'e\\f'g});
parse(q{"a\b\\c\\\d\"e\\\\f\"g"}, q{a\b\c\\d"e\\f"g});


sub parse {
    my $text   = shift;
    my $expect = shift;
    my $copy   = $text;
    for ($copy) {
        s/\n/\n        /g;
        s/^\s+//;
        s/\s+$//;
    }
    my $root = $parser->try->parse(\$text);
    my $out  = '';
    if ($root) {
        $out = $generator->generate($root);
    }
    
    if ($expect) {
        is($out, $expect, $out);
    }
    else {
        print "SOURCE: $copy\n";
        if ($root) {
            print "OPTREE: $out", 
        }
        else {
            fail("!ERROR: " . $parser->reason);
        }
        my $left = $parser->remaining_text(\$text);
        print "\n";
        print "REMAIN: $left\n" if $left;
        print "\n";
    }
}

    

parse("foo bar(10) wam.bam 'hello world'");
parse(<<EOF, "var:foo; var:bar; var:baz");
# a comment
foo  # another comment
bar; # and again
; ;baz ;
   ;  # lots of delimiters
EOF

