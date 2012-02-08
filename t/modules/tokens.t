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
use constant {
    TOKENS    => 'Template::TT3::Tokens',
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

