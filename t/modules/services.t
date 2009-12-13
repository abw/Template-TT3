#============================================================= -*-perl-*-
#
# t/modules/services.t
#
# Test the Template::TT3::Services module.
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
    debug => 'Template::TT3::Services',
    args  => \@ARGV,
    tests => 10;

use Template::TT3::Services;
use Template::TT3::Context;
use constant SERVICES => 'Template::TT3::Services';

my $header = SERVICES->service( header => 'example1.tt3' );
ok( $header, 'got header service with implicit template parameter' );
is( $header->template_name, 'example1.tt3', 'service 1 has got template name' );

$header = SERVICES->service( header => { template => 'example2.tt3' } );
ok( $header, 'got header service with explicit template parameter' );
is( $header->template_name, 'example2.tt3', 'service 2 has got template name' );


#-----------------------------------------------------------------------
# manually create a pipeline
#-----------------------------------------------------------------------

my $services = SERVICES->new;
my $input    = $services->service('input');
my $pipeline = $input->connect;
my $context  = Template::TT3::Context->new(
    data => {
        name => 'World',
    }
);

my $output = $pipeline->(
    input   => [text => 'Hello [% name %]'],
    context => $context,
);
is( $output, 'Hello World', 'got simple input pipeline output' );

$header = $services->service( header => [text => "HEADER\n"] );
$pipeline = $header->connect($pipeline);

$output = $pipeline->(
    input   => [text => 'Hello [% name %]'],
    context => $context,
);
is( $output, "HEADER\nHello World", 'got input/header pipeline output' );


#-----------------------------------------------------------------------
# all-in-one
#-----------------------------------------------------------------------

$pipeline = $services->connect(
    input  => [text => "Hello [% name %]\n"],
    header => [text => "HEADER\n"],
    footer => [text => "FOOTER\n"]
);
ok( $pipeline, 'created all-in-one pipeline' );

$output = $pipeline->(
    context => $context,
);
is( $output, "HEADER\nHello World\nFOOTER\n", 'got all-in-one pipeline output' );


#-----------------------------------------------------------------------
# connecting to an existing segment
#-----------------------------------------------------------------------

$pipeline = $services->connect(
    $input,
    $header,
    footer => [text => "FOOTER\n"]
);
ok( $pipeline, 'created all-in-one pipeline from bits' );

$output = $pipeline->(
    context => $context,
    input   => [text => "Hello [% name %]!\n"],
);
is( $output, 
    "HEADER\nHello World!\nFOOTER\n", 
    'got all-in-one pipeline output from bits' 
);


