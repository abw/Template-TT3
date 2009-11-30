#============================================================= -*-perl-*-
#
# t/dialect/dialects.t
#
# Test the Template::TT3::Dialects module.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use lib 
    '/home/abw/projects/badger/lib';            # testing Badger changes
    

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    debug   => 'Template::TT3::Dialects',
    args    => \@ARGV,
    tests   => 7;

use constant 
    DIALECTS => 'Template::TT3::Dialects';

use Template::TT3::Dialects;
pass( 'loaded Template::TT3::Dialects' );

# get default dialect
my $dialect = DIALECTS->dialect;
ok( $dialect, 'got default dialect' );
is( ref $dialect, 'Template::TT3::Dialect::TT3', 'got default TT3 dialect' );

# get specific dialect
$dialect = DIALECTS->dialect('tt3');
ok( $dialect, 'got tt3 dialect' );
is( ref $dialect, 'Template::TT3::Dialect::TT3', 'got tt3 dialect module' );

# in capitals this time
$dialect = DIALECTS->dialect('TT3');
ok( $dialect, 'got TT3 dialect' );
is( ref $dialect, 'Template::TT3::Dialect::TT3', 'got TT3 dialect module' );



