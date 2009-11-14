#============================================================= -*-perl-*-
#
# t/tags/inline.t
#
# Test script for the Template::TT3::Tag::Inline class.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    tests   => 2,
    debug   => 'Template::TT3::Tag::Inline',
    args    => \@ARGV,
    import  => ':all test_expect';

use Template::TT3::Tag::Inline;
use constant {
    INLINE => 'Template::TT3::Tag::Inline',
};

my $tag = INLINE->new;
ok( $tag, 'created closed tag' );

$tag = INLINE->new( pre_chomp => 1, post_chomp => '~' );
ok( $tag, 'created closed tag with custom pre/post chomp' );

