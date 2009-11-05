#============================================================= -*-perl-*-
#
# t/module/grammar.t
#
# Test the Template::TT3::Grammar and T::TT3::Grammar::TT3 modules.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use Badger::Debug modules => 'Template::TT3::Grammar';
#use Badger::Debug modules => 'Badger::Factory';
use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 2,
    debug => 'Template::TT3::Grammar',
    args  => \@ARGV;

use Template::TT3::Grammar::TT3;
use constant {
    GRAMMAR => 'Template::TT3::Grammar',
    TT3     => 'Template::TT3::Grammar::TT3',
};

my $grammar = GRAMMAR->new;
ok( $grammar, 'created base grammar' );
#print "regex: ", $grammar->nonword_regex, "\n";

my $tt3 = TT3->new;
ok( $tt3, 'created TT3 grammar' );
#print "regex: ", $tt3->nonword_regex, "\n";

ok( $tt3->constructor('<'), 'fetched constructor for <' );
ok( $tt3->constructor('>'), 'fetched constructor for >' );
ok( $tt3->constructor('>='), 'fetched constructor for >=' );
ok( $tt3->constructor('<='), 'fetched constructor for <=' );

# ...and more...
