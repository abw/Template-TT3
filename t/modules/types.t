#============================================================= -*-perl-*-
#
# t/modules/types.t
#
# Test the Template::TT3::Types module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use Badger::Debug modules => 'Badger::Factory';
use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 1,
    debug => 'Badger::Factory Template::TT3::Types',
    args  => \@ARGV;

use Template::TT3::Types;
use constant TYPES => 'Template::TT3::Types';

use Template::TT3::Type::List;

ok( TYPES->preload, 'preload' );


