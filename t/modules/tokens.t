#============================================================= -*-perl-*-
#
# t/modules/tokens.t
#
# Test the Template::TT3::Tokens module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use Badger::Debug 
#    modules => 'Badger::Factory';

use Badger 
    lib => '../../lib';
    
use Template::TT3::Test 
    tests => 11,
    debug => 'Template::TT3::Tokens',
    args  => \@ARGV;

use Template::TT3::Tokens;
use Template::TT3::Generator;
use constant {
    TOKENS    => 'Template::TT3::Tokens',
    GENERATOR => 'Template::TT3::Generator',
};


#-----------------------------------------------------------------------
# create a tokens list
#-----------------------------------------------------------------------

my $tlist = TOKENS->new;
ok( $tlist, 'created token list' );


#-----------------------------------------------------------------------
# add some tokens to the list
#-----------------------------------------------------------------------

ok( $tlist->whitespace_token('# blah'), 'added some whitespace' );
ok( $tlist->text_token('this is some text'), 'added some text' );
ok( $tlist->whitespace_token('    '), 'added some more whitespace' );
ok( $tlist->whitespace_token('# yada'), 'added a comment' );
ok( $tlist->text_token('this is some more text'), 'added some more text' );
ok( $tlist->whitespace_token('# rhubarb'), 'added a final comment' );
is( $tlist->size, 6, 'added 6 tokens' );


#-----------------------------------------------------------------------
# test we can skip over whitespace
#-----------------------------------------------------------------------

my $token = $tlist->first->skip_ws;
is( $token->text, 'this is some text', 'first non-whitespace token' );

$token = $token->next_skip_ws;
is( $token->text, 'this is some more text', 'second non-whitespace token' );

ok( ! $token->next_skip_ws, 'no more non-whitespace tokens' );

__END__

while ($token) {
    print "NON-WS: ", $token->generate($gen), "\n";
    $token = $token->next_skip_ws;
}


my $gen = GENERATOR->new;
print $tlist->generate($gen), "\n\n";

# Now that we have a single linked list of tokens, we can always fetch
# the next token following the current one.  We can give each token type
# a skip_ws() method that Does The Right Thing (for whitespace return the
# next token, for non-whitespace return $self)

my $token = $tlist->first->skip_ws;

while ($token) {
    print "NON-WS: ", $token->generate($gen), "\n";
    $token = $token->next_skip_ws;
}

