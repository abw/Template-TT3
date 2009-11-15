#============================================================= -*-perl-*-
#
# t/module/tagset.t
#
# Test the Template::TT3::Tagset module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
#use Badger::Debug modules => 'Template::TT3::Tagset Template::TT3::Tag';
use Template::TT3::Test 
    debug => 'Template::TT3::Tagset',
    args  => \@ARGV,
    tests => 39;

use Template::TT3::Tagset::TT3;
use constant TAGSET => 'Template::TT3::Tagset::TT3';

my $tagset = TAGSET->new();
ok( $tagset, "created tagset: $tagset" );


# set inline tag with a single argument
ok( 
    $tagset->change( '[- -]' ),
    'changed tagset with a single string'
);
is( $tagset->tag('default')->start, '[-', 'changed default start tag to [-' );
is( $tagset->tag('default')->end  , '-]', 'changed default end tag to -]' );
is( $tagset->tag('inline')->start, '[-', 'changed inline start tag to [-' );
is( $tagset->tag('inline')->end  , '-]', 'changed inline end tag -]' );
is( $tagset->tag('comment')->start, '[#', 'comment start tag is unchanged' );
is( $tagset->tag('comment')->end  , '#]', 'comment end tag is unchanged' );


# set inline tag with a single list ref
ok( 
    $tagset->change(['[@',  '@]']),
    'changed tagset with two strings'
);
is( $tagset->tag('default')->start, '[@', 'changed default start tag to [@' );
is( $tagset->tag('default')->end  , '@]', 'changed default end tag to @]' );
is( $tagset->tag('inline')->start, '[@', 'changed inline start tag to [@' );
is( $tagset->tag('inline')->end  , '@]', 'changed inline end tag @]' );


# set inline tag by name - should also be accessible as 'default' tag
ok( 
    $tagset->change( inline => '[* *]' ),
    'changed tagset inline'
);
is( $tagset->tag('default')->start, '[*', 'changed default start tag to [*' );
is( $tagset->tag('default')->end  , '*]', 'changed default end tag to *]' );
is( $tagset->tag('inline')->start, '[*', 'changed inline start tag to [*' );
is( $tagset->tag('inline')->end  , '*]', 'changed inline end tag *]' );


# should be able to use 'default' name as alias for first tag
ok( 
    $tagset->change( default => '<* *>' ),
    'changed tagset default'
);
is( $tagset->tag('default')->start, '<*', 'changed default start tag to <*' );
is( $tagset->tag('default')->end  , '*>', 'changed default end tag to *>' );
is( $tagset->tag('inline')->start, '<*', 'changed inline start tag to <*' );
is( $tagset->tag('inline')->end  , '*>', 'changed inline end tag to *>' );


# set several tags at once
ok( 
    $tagset->change( inline => '(* *)', comment => '<# #>' ),
    'changed tagset inline and comment'
);
is( $tagset->tag('default')->start, '(*', 'changed default start tag to (*' );
is( $tagset->tag('default')->end  , '*)', 'changed default end tag to *)' );
is( $tagset->tag('inline')->start, '(*', 'changed inline start tag to (*' );
is( $tagset->tag('inline')->end  , '*)', 'changed inline end tag to *)' );
is( $tagset->tag('comment')->start, '<#', 'changed comment start tag to <#' );
is( $tagset->tag('comment')->end  , '#>', 'changed comment end tag to #>' );


# check we get an error if we set any invalid tag names
ok( 
    ! $tagset->try->change( frusset => '(* *)', pouch => '<* *>' ),
    'did not change tagset with invalid tag name'
);
is( 
    $tagset->reason->info, 'Invalid tags specified: frusset, pouch',
    'got error message reporting invalid tags'
);


# reset tags 
ok( 
    $tagset->reset,
    'reset tagset'
);
is( $tagset->tag('default')->start, '[%', 'reset default start tag to [%' );
is( $tagset->tag('default')->end  , '%]', 'reset default end tag to %]' );
is( $tagset->tag('inline')->start, '[%',  'reset inline start tag to [%' );
is( $tagset->tag('inline')->end  , '%]',  'reset inline end tag to %]' );
is( $tagset->tag('comment')->start, '[#', 'reset comment start tag to [#' );
is( $tagset->tag('comment')->end  , '#]', 'reset comment end tag to #]' );

exit;


print "*** changed tags\n";

print $tagset->dump;

print "*** resetting tags\n";

$tagset->reset;

print "*** reset tags\n";

print $tagset->dump;


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
