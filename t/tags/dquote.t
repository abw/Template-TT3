#============================================================= -*-perl-*-
#
# t/tags/dquote.t
#
# Test the double quoted string tokenising capabilities of the 
# Template::TT3::Tag module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    skip    => 'Just testing...',
    tests   => 6,
    debug   => 'Template::TT3::Tag',
    args    => \@ARGV;

use Template::TT3::Tag;
use Template::TT3::Tokens;
use constant {
    TAG    => 'Template::TT3::Tag',
    TOKENS => 'Template::TT3::Tokens',
};

my $tag = TAG->new;
ok( $tag, 'created a tag' );

my $tokens = TOKENS->new;
ok( $tokens, 'created a token stream' );

test_string( q{foo bar} );
test_string( q{foo " bar} );
test_string( q{foo \n bar} );
test_string( q{foo \"bar\" baz} );
test_string( q{foo $bar} );

sub test_string {
    my $string = shift;
    my $source = "NOT USED";
    my $tokens = TOKENS->new;

    print "STRING: [$string]\n";

    my $token = $tag->tokenise_string(
        # cleaning up this mess of arguments is TODO
        \$source, $tokens, undef,
        '"' . $string . '"', 0, $string, 
        '"'
    );
    
    print "** TOKEN: $token\n";
    print $tokens->view_HTML;
}

