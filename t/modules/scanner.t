#use Badger::Debug modules => 'Badger::Factory';
use Badger lib => '../../lib';

use Template::TT3::Test 
    skip  => 'Work in progress...',
    tests => 6,
    debug => 'Template::TT3::Scanner',
    args  => \@ARGV;

use utf8;
use Template::TT3::Scanner;
use Template::TT3::Generator::Debug;
use Template::TT3::Generator::Source;
use Template::TT3::Generator::DebugExpr;
use constant {
    SCANNER   => 'Template::TT3::Scanner',
    TAG       => 'Template::TT3::Tag',
    TLIST     => 'Template::TT3::Tokens',
    GENERATOR => 'Template::TT3::Generator::Debug',
    SOURCE    => 'Template::TT3::Generator::Source',
    GENEXPR   => 'Template::TT3::Generator::DebugExpr',
};


my $scanner = SCANNER->new();
ok( $scanner, 'created scanner' );

$text =<<'EOF';
not [% not a + b %]
not [% ! a + b %]
EOF

exit();

__END__
#-----------------------------------------------------------------------
# setup
#-----------------------------------------------------------------------

my $dirtag = TAG->new(
    start => '[%',
    end   => '%]',
    # TODO: I don't think we need keywords - they belong to the parser,
    # not the tag... hmmm... no, on second thoughts, we need to bless tokens 
    # into the appropriate element class
    keywords => {
        foo => 'FOO',
        bar => 'BAR',
    }
);
ok( $dirtag, 'created directive tag' );

my $vartag = TAG->new(
    start => '${',
    end   => '}',
);
ok( $vartag, 'created variable tag');

my $scanner = SCANNER->new( 
    tags => [ $dirtag, $vartag ],
);
ok( $scanner, 'created scanner' );

my $gen = GENERATOR->new;
ok( $gen, 'created generator');

my $src = SOURCE->new;
ok( $src, 'created source re-generator');

my $genexpr = GENEXPR->new;
ok( $genexpr, 'created expression debug generator');


#-----------------------------------------------------------------------
# scan for tokens
#-----------------------------------------------------------------------

my $text =<<'EOF';
hello world
hello [% user.name %]
some more text
[% foo + bar < 42 ? 'Wow!' : "Crazy!"  # a comment at the end of a tag %]
even more text
${x y z # this is a comment
        # that goes on for 
        # several lines }
the end
[% 'Mark O\'Connell' %]
EOF

$text =<<'EOF';
hello [% a + b + c * d + e %]
add [% a + b + c %]
set [% a = b = c %]
inc [% ++a * b-- %]
not [% not a + b %]
not [% ! a + b %]
EOF

$text =<<'EOF';
not [% not a + b %]
not [% ! a + b %]
EOF

#$text =<<'EOF';
#do1 [% do a %]
#do2 [% do; a ; b; c; end %]
#do3 [% do { a; b; c } %]
#do4 [% do { %] a b c [% } %]
#EOF
#
#$text =<<'EOF';
#[% a → a + 1 %]
#EOF
#do1 [% do a %]
#do2 [% do; a ; b; c; end %]
#do2 [% do; a; b; c; end %]

#$text = $text x 1000;

#while ($text =~ /\G(.)/gcsx) {
#    print $1
#}

    
#my $tokens = $scanner->scan($text);

#ok( $tokens, "got tokens: $tokens" );
#is( $tokens->size, 24, 'got 24 tokens' );

print "string length: ", length($text), "\n";

#print "done\n"; exit;

test_scanner($text);

print "finished\n";

sub test_scanner {
    my $input  = shift;
    print "scanning tokens\n";
    my $tokens = $scanner->scan($input);

    print "generating token output\n";
    
    my $output = $tokens->generate($src);

#    print "--------------------------------------------------------\n";
#    print "SOURCE:\n", $text, "\n";
#    print "--------------------------------------------------------\n";
#    print $tokens->generate($gen), "\n";
#   print "--------------------------------------------------------\n";
    print "REGEN:\n", $tokens->generate($src), "\n";
#    print "========================================================\n\n";


    print "comparing\n";
    if ($input eq $output) {
        pass("input matches");
    }
    else {
        fail("input does not match");
    }

    my $token = $tokens->first;
    my $expr;
    my $n = 1;
    my @exprs;
    
#    while ($expr = $token->skip_ws(\$token)->as_expr(\$token)) {
#    print "---\n";
    while ($expr = $token->as_expr(\$token)) {
        print " expr: $expr\n";
        print "token: $token\n";
        push(@exprs, $expr);
 #       print "-";
    }
#    print "\n";

    print "winding\n";
    
    while (! $token->eof) {
        print "!!!! Unparsed: $token\n";
        $token = $token->next;
    }

    print "\n\n** EXPRESSIONS **\n";
    print $genexpr->generate_tokens(\@exprs);
    print "finishing\n";

}

    

__END__
my $first = $tlist->first->skip_ws;

while ($first) {
    print "NON-WS: ", $first->generate($gen), "\n";
    $first = $first->next_skip_ws;
}

__END__
#print join(', ', @$tokens);

print display($tokens);



sub display {
    my $tokens = shift;
    join(
        "\n",
        map { 
            my $text = $_->[1];
            $text =~ s/\n/\\n/g;
            "[$_->[0] => $text]" 
        }
        @$tokens
    );
}
