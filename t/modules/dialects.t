#============================================================= -*-perl-*-
#
# t/modules/dialects.t
#
# Test the Template::TT3::Dialects module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use lib
    '/home/abw/projects/badger/lib';

#use Badger::Debug
#    modules => 'Badger::Factory';

use Badger 
    lib => '../../lib';

use Template::TT3::Test 
    debug => 'Template::TT3::Dialects Template::TT3::Tagset',
    args  => \@ARGV,
    tests => 4;

use Template::TT3::Dialects;
use constant DIALECTS => 'Template::TT3::Dialects';
pass('loaded Template::TT3::Dialects' );

#my $tt3 = DIALECTS->dialect('tt3');
#ok( $tt3, 'got tt3 dialect from class' );

my $dialects = DIALECTS->new( dialects => { tt3 => { hello => 'world' } } );
ok( $dialects, 'created dialects object');

my $tt3 = $dialects->dialect('tt3');
ok( $tt3, 'got tt3 dialect from object' );

my $tagset = $tt3->tagset;
ok( $tagset, 'got tagset' );

#print $tagset->dump;