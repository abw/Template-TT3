#============================================================= -*-perl-*-
#
# t/modules/hub.t
#
# Test the Template::TT3::Hub module.
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
    
use Template::TT3::Test 
    debug => 'Template::TT3::Hub',
    args  => \@ARGV,
    tests => 5;

use Template::TT3::Hub;
use constant HUB => 'Template::TT3::Hub';

ok( 1, 'loaded Template::TT3::Hub' );

# should be able to use it as a prototype/singleton
my $providers = HUB->providers;
ok( $providers, 'fetched providers' );

my $file = HUB->provider( file => { path => '/tmp' } );
ok( $file, 'fetched file provider' );

my $data = HUB->input_glob(\*DATA);
chomp $data;
is( $data, 'Hello World!', 'input_glob() read from __DATA__' );

$data = HUB->input_handle( Bin->dir('templates')->file('hello.tt3')->open );
chomp $data;
is( $data, q{Hello [% name or 'World' %]!}, 'input_fh() read from hello.tt3' );

__DATA__
Hello World!
