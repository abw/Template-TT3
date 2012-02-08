#============================================================= -*-perl-*-
#
# t/modules/template.t
#
# Test the Template::TT3::Template module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug => 'Template::TT3::Template',
    args  => \@ARGV,
    tests => 6;

use Template::TT3::Template;
use constant TEMPLATE => 'Template::TT3::Template';

my $template = TEMPLATE->new( text => 'hello world' );
ok( $template, 'created template' );

my $text = $template->text;
is( $text, 'hello world', 'got template text' );

my $source = $template->source;
is( $$source, 'hello world', 'got template source' );
is( $source, 'hello world', 'got template source via auto-stringification' );

$template = TEMPLATE->new( text => 'How about a nice [% a.b.first + 20 %]?' );
ok( $template, 'created another template' );

my $output = $template->fill( a => { b => [400] } );
is( $output, 'How about a nice 420?', 'got template output' );

