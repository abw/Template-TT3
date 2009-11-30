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

#use lib
#    '/home/abw/projects/badger/lib';

#use Badger::Debug
#    modules => 'Badger::Factory';

use Badger 
    lib => '../../lib';

use Template::TT3::Test 
    debug => 'Template::TT3::Dialects Template::TT3::Dialect',
    args  => \@ARGV,
    tests => 12;


#-----------------------------------------------------------------------
# basic tests
#-----------------------------------------------------------------------

use Template::TT3::Dialects;
use constant DIALECTS => 'Template::TT3::Dialects';
pass('loaded Template::TT3::Dialects' );

my $tt3 = DIALECTS->dialect('tt3');
ok( $tt3, 'got tt3 dialect from class' );

is( $tt3->name, 'tt3', 'got dialect name' );
is( "$tt3", 'tt3', 'got dialect name by auto-stringification' );

my $tagset = $tt3->tagset;
ok( $tagset, 'got tagset' );


#-----------------------------------------------------------------------
# customising an existing dialect
#-----------------------------------------------------------------------

my $dialects = DIALECTS->new( 
    dialects => { 
        tt3 => { 
            tags => '<* *>',
        }
    } 
);
ok( $dialects, 'created dialects object');

$tt3 = $dialects->dialect('tt3');
ok( $tt3, 'got tt3 dialect from object' );

$tagset = $tt3->tagset;
#print $tagset->dump;

my $scanner = $tt3->scanner;
ok( $scanner, 'got scanner' );

$tagset = $scanner->tagset;
ok( $tagset, 'got scanner tagset' );

my $inline = $tagset->tag('inline');
ok( $inline, 'got inline tag' );
is( $inline->start, '<*', 'inline start is set to <*' );
is( $inline->end, '*>', 'inline end is set to *>' );
