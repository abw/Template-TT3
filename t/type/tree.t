#============================================================= -*-perl-*-
#
# t/type/tree.t
#
# Test the Template::TT3::Type::Tree module.
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
    debug  => 'Template::TT3::Type::Tree',
    args   => \@ARGV,
    tests  => 5;

use Template::TT3::Type::Tree qw(TREE Tree);

ok( 1, 'loaded tree' );

is( TREE, 'Template::TT3::Type::Tree', 'got TREE' );

my $tree = Tree( root => 'hello' );
ok( $tree, 'created Tree' );


use Template::TT3::Scanner;

my $tokens = Template::TT3::Scanner->new->scan("Hello [% name %]");
ok( $tokens, "got scanned tokens: $tokens" );

$tree = $tokens->tree;
ok( $tree, "got tree: $tree" );


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
