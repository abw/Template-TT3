#============================================================= -*-perl-*-
#
# t/modules/tokeniser.t
#
# Test the Template::TT3::Tokeniser module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    skip  => 'Old code... being refactored out of existence',
    tests => 1,
    debug => 'Template::TT3::Tokeniser',
    args  => \@ARGV;
#use re 'debug';

use Template::TT3::Tokeniser;
use constant {
    TOKENISER => 'Template::TT3::Tokeniser',
};

my $tokeniser = TOKENISER->new( tag_end => '%]' );
ok( $tokeniser, 'created tokeniser' );

tokenise(<<EOF);
foo bar
# this is a comment
foo + 10   # this is also a comment
'string' + 99 
the end # comment %]
after
EOF

sub tokenise {
    my $text   = shift;
    my $expect = shift;
    my $copy   = $text;
    for ($copy) {
        s/\n/\n        /g;
        s/^\s+//;
        s/\s+$//;
    }
    my $tokens = $tokeniser->try->tokens(\$text);
    my $out  = '';
    if ($tokens) {
        $out = display($tokens);
    }
    
    if ($expect) {
        is($out, $expect, $out);
    }
    else {
        print "SOURCE: $copy\n";
        if ($tokens) {
            print "TOKENS: $out", 
        }
        else {
            fail("!ERROR: " . $tokeniser->reason);
        }
    }
}

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
