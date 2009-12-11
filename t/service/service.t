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

use lib '/home/abw/projects/badger/lib';   # abw testing

use Badger 
    lib => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    tests => 5,
    debug => 'Template::TT3::Service Template::TT3::Service::Header',
    args  => \@ARGV;

my $tdir = Bin->dir('templates');

use Template3;
use Template::TT3::Services;
use constant SERVICES => 'Template::TT3::Services';

pass( 'Loaded ' . SERVICES );

my $tt3 = Template3->new(
    template_path => $tdir,
    header        => 'header.tt3',
    footer        => 0,             # none by default but keep the slot open
    
);
ok( $tt3, 'created template engine' );

my $output = $tt3->process('hello.tt3', name => 'Badger');

is( $output, "This is the header.\nHello Badger!\n", 'got header + content' );

$output = $tt3->render(
    input  => 'hello.tt3', 
    data   => { name  => 'Badger' },
    footer => 'footer.tt3'
);

is( $output, "This is the header.\nHello Badger!\nThis is the footer.\n", 'got header + content + footer' );

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

