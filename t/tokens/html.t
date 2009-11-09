#============================================================= -*-perl-*-
#
# t/tokens/html.t
#
# Convert template tokens into HTML.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 2,
    debug => 'Template::TT3::Generator::Tokens::HTML',
    args  => \@ARGV;

use Template::TT3::Template;
use constant TEMPLATE => 'Template::TT3::Template';


my $template = TEMPLATE->new( text => <<EOF );
Hello [% name or 'World' %]
EOF

ok( $template, 'created template' );
my $html = $template->tokens->html;
ok( $html, 'got generated HTML' );
#print "html: ", $html, "\n";