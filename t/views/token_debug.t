#============================================================= -*-perl-*-
#
# t/views/token_debug.t
#
# Tests for the Template::TT3::View::Tokens::Debug module.
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
    tests => 3,
    debug => 'Template::TT3::View::Tokens::Debug',
    args  => \@ARGV;

use Template::TT3::Template;
use constant {
    Template => 'Template::TT3::Template',
};

my $template = Template->new( text => <<EOF );
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
ok( $tokens->view_debug( show_refs => 1 ), 'generated token debug output' );
