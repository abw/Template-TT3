#============================================================= -*-perl-*-
#
# t/modules/scanner.t
#
# Test the Template::TT3::Scanner module.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib';

use Template::TT3::Test 
    debug => 'Template::TT3::Scanner Template::TT3::Tagset',
    args  => \@ARGV,
    tests => 16;

use utf8;
use Template::TT3::Scanner;
use Template::TT3::Tag::Comment;
use constant {
    SCANNER => 'Template::TT3::Scanner',
};

pass( 'loaded Template::TT3::Scanner' );

my $scanner = SCANNER->new;
ok( $scanner, 'created scanner' );

my $text =<<'EOF';
not [% not a + b %]
not [% ! a + b %]
EOF

my $tokens = $scanner->scan($text);
ok( $tokens, 'got tokens from scanner' );

my $regen = $tokens->text;
is( $regen, $text, 'regenerated token text matches input' );


#-----------------------------------------------------------------------
# custom scanner
#-----------------------------------------------------------------------

    
my $tag = Template::TT3::Tag::Comment->new(
    start => '<#',
    end   => '#>',
);
    
$scanner = Template::TT3::Scanner->new(
    tagset => {
        comment => $tag
    }
);

$text =<<'EOF';
blah [% blah %] [? blah ?] [# blah #]
%% blah
All of the above are ignored,
but <# this is a comment #>
this is the end
EOF

$tokens = $scanner->scan($text);
ok( $tokens, 'got tokens from custom scanner' );

is( $tokens->size, 4, 'got 4 tokens' );

my $token = $tokens->first;
is( $token->type, 'text', 'got a text token' );
is( $token->length, 80, 'text is the correct length' );

$token = $token->next;
is( $token->type, 'comment', 'got a comment token' );
is( $token->length, 23, 'comment is the correct length' );

$token = $token->next;
is( $token->type, 'text', 'got some more text' );
is( $token->length, 17, 'comment is the correct length' );



#-----------------------------------------------------------------------
# custom replacement scanner
#-----------------------------------------------------------------------

$scanner = Template::TT3::Scanner->new(
    tagset => {
        bold => {
            start   => '[b]',
            end     => '[/b]',
            type    => 'replace',
            replace => sub {
                my ($self, $text) = @_;
                return "<b>$text</b>";
            }
        },
        italic => {
            start   => '[i]',
            end     => '[/i]',
            type    => 'replace',
            replace => sub {
                my ($self, $text) = @_;
                return "<i>$text</i>";
            }
        },
    }
);
ok( $scanner, 'created scanner with replace tags' );
    
$text =<<'EOF';
This is [b]some bold text[/b]
This is [i]some italic text[/i]
EOF

my $expect =<<'EOF';
This is <b>some bold text</b>
This is <i>some italic text</i>
EOF

$tokens = $scanner->scan($text);
ok( $tokens, 'scanned bold/italic text' );
is( $tokens->expr->text, $expect, 'output matches expected' );

# try the all-in-one transform() method
my $output = $scanner->transform($text);
is( $output, $expect, 'transform output matches expected' );

#print $tokens->tree->text;


