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

#use Badger::Debug modules => 'Template::TT3::Types Badger::Factory';
use Badger lib => '../../lib';
#use Badger::Debug modules => 'Template::TT3::Scanner';
use Template::TT3::Test 
#    debug => 'Template::TT3::Template',
    args  => \@ARGV,
    debug => 'Template::TT3::Scanner',
    tests => 5;

use Template::TT3::Template;
use constant TEMPLATE => 'Template::TT3::Template';

use Template::TT3::Generator::Debug;
use constant GENERATOR => 'Template::TT3::Generator::Debug';
my $gen = GENERATOR->new;

my $template = TEMPLATE->new( text => 'hello world' );
ok( $template, 'created template' );

my $text = $template->text;
is( $text, 'hello world', 'got template text' );

my $source = $template->source;
is( $$source, 'hello world', 'got template source' );
is( $source, 'hello world', 'got template source via auto-stringification' );

my $tokens = $template->tokens;

#print $tokens->generate($gen), "\n";

#$template = TEMPLATE->new( text => '[% 4 + 20; 5 + 8 * 2; 5 + 5 %]' );
$template = TEMPLATE->new( text => 'How about a nice [% a.b.first + 20 %]?' );
my $sexpr = $template->sexpr;

my $output = $template->fill( a => { b => [400] } );
is( $output, 'How about a nice 420?', 'got template output' );

#print $sexpr, "\n\n";
#print "-------\n";
#print "FILL: ", $template->fill( a => { b => [400] } ), "\n";

#my $exprs = $template->exprs;

#print "\n======\n";
#print "OUTPUT TEXT: [", $exprs->text, "]\n";
#print "OUTPUT VALUES: [", join(', ', $exprs->values), "]\n";
