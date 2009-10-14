#============================================================= -*-perl-*-
#
# t/modules/variable.t
#
# Test the Template::TT3::Variable module.
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
    debug => 'Template::TT3::Variable',
    args  => \@ARGV;

use Template::TT3::Variable;
use constant VAR => 'Template::TT3::Variable';

my $constructor = VAR->constructor;
ok( $constructor, 'got constructor' );
is( ref $constructor, 'CODE', 'constructor is a code ref' );


