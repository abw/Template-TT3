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

parse("a.b.c.d");
parse("a(1).b(2,3).c(4).d(5,e(6))");
parse("foo(a(101),b).bar(c,\nd # hello\n e) # a comment\n.baz");

parse("fill x");
parse("var:x");
parse("var:");
parse("q:(some text)");
parse("q:[more text]");
parse("q:(more text)");
parse("q:<more text>");
parse("q:{more text}");
parse(q{'Tam O\'Shanter'});
parse(q{q:'Tam O\'Shanter'});
parse(q{q:<Tam O'Shanter>});
parse(q{q:<10 \> 9>});
parse(q{q:[a\\\\b\\]\c\\\\]});
parse(<<'EOF');
q:<a\b\\c\\\d\\\\e>
EOF

parse("foo bar(10) wam.bam 'hello world'");
parse(<<EOF);
# a comment
foo  # another comment
bar; # and again
; ;baz ;
   ;  # lots of delimiters
EOF

parse('"foo"');
parse('"foo\"bar"');
parse('"foo\bar\\baz\\\bam"');
parse('"foo\nbar\tbaz\\bam\"END"');
#print "result: $result\n";

#print $parser->dump_data($result);

sub parse {
    my $text = shift;
    my $copy = $text;
    for ($copy) {
        s/\n/\n        /g;
        s/^\s+//;
        s/\s+$//;
    }
    print "SOURCE: $copy\n";
    my $root = $parser->try->parse(\$text);
    if ($root) {
        print "OPTREE: ", $generator->generate($root);
    }
    else {
        print "!ERROR: ", $parser->reason;
    }
    my $left = $parser->remaining_text(\$text);
    print "\n";
    print "REMAIN: $left\n" if $left;
    print "\n";
}
