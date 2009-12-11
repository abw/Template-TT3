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
    tests => 4;

use Template::TT3::Services;
use constant SERVICES => 'Template::TT3::Services';

my $header = SERVICES->service( header => 'example1.tt3' );
ok( $header, 'got header service with implicit template parameter' );
is( $header->template, 'example1.tt3', 'service 1 has got template name' );

$header = SERVICES->service( header => { template => 'example2.tt3' } );
ok( $header, 'got header service with explicit template parameter' );
is( $header->template, 'example2.tt3', 'service 2 has got template name' );