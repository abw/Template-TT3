#============================================================= -*-perl-*-
#
# t/modules/generators.t
#
# Test the Template::TT3::Generators module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    skip  => 'Generators are deprecated... now called Views',
    debug => 'Badger::Factory Template::TT3::Generators',
    args  => \@ARGV,
    tests => 4;

use Template::TT3::Generators;
use constant GENERATORS => 'Template::TT3::Generators';

my $src_gen = GENERATORS->generator('source');
ok( $src_gen, 'got source generator' );
is( 
    ref $src_gen, 
    'Template::TT3::Generator::Source', 
    'isa Template::TT3::Generator::Source' 
);

#my $tok_gen = GENERATORS->generator('tokens.HTML');
#ok( $tok_gen, 'got token HTML generator' );
#is( 
#    ref $tok_gen, 
#    'Template::TT3::Generator::Tokens::HTML', 
#    'isa Template::TT3::Generator::Tokens::HTML' 
#);
