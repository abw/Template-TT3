#============================================================= -*-perl-*-
#
# t/views/tokens_html.t
#
# Tests for the Template::TT3::View::Tokens::HTML module.
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
    tests  => 5,
    debug  => 'Template::TT3::View::Tokens::HTML',
    args   => \@ARGV;

use Template3;

my $template = Template3->template( text => <<EOF );
Hello [% name %]
This is a test
[% # a comment
   a + 10
   fill foo.bar
=%]
more text
%% a is b
the end
EOF

ok( $template, 'created template' );
my $tokens = $template->tokens;

ok( $tokens, 'got tokens' );
my $source = $tokens->view_HTML( view => 'source' );
ok( $source, 'generated tokens HTML source output' );

manager->debug( "Generated HTML source:\n", $source )
    if $DEBUG;

my $tokdump = $tokens->view_HTML( view => 'tokens' );
ok( $tokdump, 'generated tokens HTML token dump output' );

manager->debug( "Generated HTML tokens:\n", $tokdump )
    if $DEBUG;

# we had some problems with views being cached - this checks that we've
# at least got different output from the two views
isnt( $source, $tokdump, 'source and token dump are different' );
