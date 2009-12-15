#============================================================= -*-perl-*-
#
# t/service/service.t
#
# Test the Template::TT3::Service::* modules
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

use Template::TT3::Test 
    tests => 19,
    debug => 'Template::TT3::Service Template::TT3::Services',
    args  => \@ARGV;

my $tdir = Bin->dir('templates');
my $data = {
    name => 'Badger',
};

use Template3;
use Template::TT3::Services;
use constant SERVICES => 'Template::TT3::Services';

pass( 'Loaded ' . SERVICES );

#-----------------------------------------------------------------------
# header and footer
#-----------------------------------------------------------------------

my $tt3 = Template3->new(
    template_path => $tdir,
    header        => 'header.tt3',  # specify a default header
    footer        => 0,             # none by default but keep the slot open
    
);
ok( $tt3, 'created template engine' );

# The process() method is for quick-and-simple template processing with 
# minimal fuss.  It uses the service defaults.

my $output = $tt3->process('hello.tt3', $data);

is( $output, 
    "This is the header.\nHello Badger!\n", 
    'got header + content' 
);

# The render() method expects named parameters that define the service
# environment.  It's more long-winded but you can change the service 
# parameters.  Here we specify a footer to add to over-ride the default 
# value of 0 (no footer).  Note that we must mention the footer in the 
# TT3 configuration (i.e. set it to a defined but false value) otherwise
# it will be optimised out of the pipeline.

$output = $tt3->render(
    input  => 'hello.tt3', 
    data   => $data,
    footer => 'footer.tt3'
);

is( $output, 
    "This is the header.\nHello Badger!\nThis is the footer.\n", 
    'got header + content + footer' 
);

# Let's switch the header and footer around just to prove that we can

$output = $tt3->render(
    input  => 'hello.tt3', 
    data   => { name  => 'Badger' },
    header => 'footer.tt3',
    footer => 'header.tt3',
);

is( $output, 
    "This is the footer.\nHello Badger!\nThis is the header.\n", 
    'got footer + content + header from service' 
);


#-----------------------------------------------------------------------
# wrapper
#-----------------------------------------------------------------------

use Badger::Constants 'BLANK';

# Again we must specify a defined but false value for 'wrapper' up front
# so that it is included in the service pipeline

$tt3 = Template3->new(
    template_path => $tdir,
    wrapper       => BLANK,
);

# Because 'wrapper' is set to false we don't get any wrapper by default.

ok( $tt3, 'created template engine with BLANK wrapper' );
is( $tt3->process('hello.tt3', name => 'Badger' ), 
    "Hello Badger!\n", 
    'no wrapper' 
);

# But we can specify one explicitly

$output = $tt3->render( 
    input   => 'hello.tt3', 
    data    => $data,
    wrapper => 'wrapper.tt3',
);

is( $output,
    "[WRAPPER]\nHello Badger!\n[/WRAPPER]\n", 
    'with wrapper' 
);


#-----------------------------------------------------------------------
# layout
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    template_path  => $tdir,
    layout         => 'layout.tt3',
);

ok( $tt3, 'created template engine with layout' );
is( $tt3->process('laidout.tt3', name => 'Badger' ), 
    "Hello Badger!cccccc\n", 
    'custom layout' 
);


exit();


#-----------------------------------------------------------------------
# aliases
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    template_path  => $tdir,
    site_header    => { type => 'header' },
    section_footer => { type => 'footer' },
    service        => 'site_header section_footer',
);

ok( $tt3, 'created template engine with custom service' );
is( $tt3->process('hello.tt3', name => 'Badger' ), 
    "Hello Badger!\n", 
    'no custom service' 
);

$output = $tt3->render(
    input          => 'hello.tt3',
    data           => $data,
    site_header    => 'header.tt3',
    section_footer => 'greeting.tt3',
);

is( $output,
    "This is the header.\nHello Badger!\nThat's a very nice coat you're wearing.\n", 
    'custom service with a very nice coat' 
);


#-----------------------------------------------------------------------
# shortcuts for lazy people like me
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    template_path  => $tdir,
    site_header    => BLANK,
    section_footer => BLANK,
    service        => 'header:site_header footer:section_footer',
);

ok( $tt3, 'created template engine with custom service' );
is( $tt3->process('hello.tt3', name => 'Badger' ), 
    "Hello Badger!\n", 
    'no custom service for lazy people' 
);

$output = $tt3->render(
    input          => 'hello.tt3',
    data           => $data,
    site_header    => 'header.tt3',
    section_footer => 'greeting.tt3',
);

is( $output,
    "This is the header.\nHello Badger!\nThat's a very nice coat you're wearing.\n", 
    'custom service with a very nice coat for lazy people' 
);

# Run it again just to be sure that the service repeats OK... 

$output = $tt3->render(
    input          => 'hello.tt3',
    data           => $data,
    site_header    => 'header.tt3',
    section_footer => 'greeting.tt3',
);

is( $output,
    "This is the header.\nHello Badger!\nThat's a very nice coat you're wearing.\n", 
    'custom service with a very nice coat for very lazy people' 
);


#-----------------------------------------------------------------------
# define several different services
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    template_path => $tdir,
    services => {
        default => 'wrapper',
        clothed => 'header footer wrapper',
        naked   => [ ],
    },
    wrapper => 'wrapper.tt3',
    header  => 'header.tt3',
    footer  => BLANK,
);

$output = $tt3->render(
    input   => 'hello.tt3',
    data    => $data,
);
is( $output, 
    "[WRAPPER]\nHello Badger!\n[/WRAPPER]\n", 
    'got default service' 
);

$output = $tt3->render(
    input   => 'hello.tt3',
    data    => $data,
    service => 'naked',
);
is( $output, 
    "Hello Badger!\n", 
    'got naked service' 
);

$output = $tt3->render(
    input   => 'hello.tt3',
    data    => $data,
    service => 'clothed',
);
is( $output, 
    "[WRAPPER]\nThis is the header.\nHello Badger!\n[/WRAPPER]\n", 
    'got clothed service' 
);

$output = $tt3->render(
    input   => 'hello.tt3',
    data    => $data,
    service => 'clothed',
    footer  => 'footer.tt3',
);
is( $output, 
    "[WRAPPER]\nThis is the header.\nHello Badger!\nThis is the footer.\n[/WRAPPER]\n", 
    'got clothed service with extra footer' 
);

