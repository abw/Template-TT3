#============================================================= -*-perl-*-
#
# t/modules/scope.t
#
# Test the Template::TT3::Scope module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug => 'Template::TT3::Scope',
    args  => \@ARGV,
    tests => 2;

use Template::TT3::Scope;
use constant SCOPE => 'Template::TT3::Scope';

ok( 1, 'loaded Template::TT3::Scope' );

my $scope = SCOPE->new;
ok( $scope, 'created scope object' );


