#============================================================= -*-perl-*-
#
# t/modules/context.t
#
# Test the Template::TT3::Context module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug => 'Template::TT3::Context',
    args  => \@ARGV,
    tests => 2;

use Template::TT3::Context;
use constant CONTEXT => 'Template::TT3::Context';

ok( 1, 'loaded Template::TT3::Context' );

my $context = CONTEXT->new;
ok( $context, 'created context object' );


