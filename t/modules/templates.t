#============================================================= -*-perl-*-
#
# t/modules/templates.t
#
# Test the Template::TT3::Templates module.
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
    lib => '../../lib',
    Filesystem => 'Bin';

#use Badger::Debug modules => 'Template::TT3::Templates';       # abw testing

use Template::TT3::Test 
    args  => \@ARGV,
    debug => 'Template::TT3::Templates',
    tests => 27;

use Template::TT3::Templates;
use constant TEMPLATES => 'Template::TT3::Templates';

pass( 'loaded ' . TEMPLATES );

my $templates = TEMPLATES->new( 
    template_path => Bin->dir('templates'),
    path_expires  => 5,
);
my ($template, $input, $output);


#-----------------------------------------------------------------------
#  templates from text
#-----------------------------------------------------------------------

$template = $templates->template( text => 'Hello [% name %]' );
ok( $template, 'got text template with explicit type' );
is( $template->fill( name => 'Badger' ), 'Hello Badger', 'Hello Badger' );

$template = $templates->template([ text => 'Wazzup [% name %]' ]);
ok( $template, 'got text template from list pair' );
is( $template->fill( name => 'Badger' ), 'Wazzup Badger', 'Wazzup Badger' );

$template = $templates->template({ text => 'Hey [% name %]' });
ok( $template, 'got text template from hash pair' );
is( $template->fill( name => 'Badger' ), 'Hey Badger', 'Hey Badger' );

$template = $templates->template({ type => 'text', text => 'Yo [% name %]' });
ok( $template, 'got text template from wider hash' );
is( $template->fill( name => 'Badger' ), 'Yo Badger', 'Yo Badger' );

$input = 'Goodbye [% name %]';
$template = $templates->template( \$input );
ok( $template, 'got text template from text ref' );
is( $template->fill( name => 'Badger' ), 'Goodbye Badger', 'Goodbye Badger' );


#-----------------------------------------------------------------------
# template from a glob/filehandle
#-----------------------------------------------------------------------

$template = $templates->template( \*DATA );
ok( $template, 'got text template from glob' );
$output = $template->fill( name => 'Badger' );
chomp $output;
is( $output, 'Good-day Badger', $output );

$template = $templates->template( Bin->dir('templates')->file('hello.tt3')->open );
ok( $template, 'got text template from filehandle' );
$output = $template->fill( name => 'Badger' );
chomp $output;
is( $output, 'Hello Badger!', $output );


#-----------------------------------------------------------------------
# template from a named file
#-----------------------------------------------------------------------

$template = $templates->template('hello.tt3');
ok( $template, 'got hello.tt3 template' );
$output = $template->fill( name => 'Ferret' );
chomp $output;
is( $output, 'Hello Ferret!', $output );

$template = $templates->template( file => 'hello.tt3' );
ok( $template, 'got hello.tt3 template file' );
$output = $template->fill( name => 'Stoat' );
chomp $output;
is( $output, 'Hello Stoat!', $output );

$template = $templates->template( name => 'hello.tt3' );
ok( $template, 'got hello.tt3 template name' );
$output = $template->fill( name => 'Weasel' );
chomp $output;
is( $output, 'Hello Weasel!', $output );

$template = $templates->template( name => 'hello.tt3' );
ok( $template, 'got hello.tt3 template name' );
$output = $template->fill( name => 'Weasel' );
chomp $output;
is( $output, 'Hello Weasel!', $output );


#-----------------------------------------------------------------------
# missing templates
#-----------------------------------------------------------------------

$template = $templates->template('missing.tt3');
ok( ! $template, 'no template called missing.tt3' );
is( $templates->reason, 'Template not found: missing.tt3', 'not found message' );


#-----------------------------------------------------------------------
# file extensions
#-----------------------------------------------------------------------

$templates = TEMPLATES->new( 
    template_path => Bin->dir('templates'),
    path_expires  => 5,
    extensions    => {
        'pod' => {
            dialect => 'pod',
        }
    },
);
ok( $templates, 'got templates object with file extension map' );
my $pod = $templates->template('test.pod');
ok( $pod, 'got pod template' );


__DATA__
Good-day [% name %]
