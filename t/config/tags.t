#============================================================= -*-perl-*-
#
# t/config/tags.t
#
# Test script for the 'tags' config option.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

#use Badger::Debug
#    modules => 'Template::TT3::Tagset';
    
use Template::TT3::Test 
    tests   => 2,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'callsign :all';

use Template::TT3::Template;
use constant
    TEMPLATE => 'Template::TT3::Template';
#    SCANNER => 'Template::TT3::Scanner';

my $template = TEMPLATE->new(
    tags => '<* *>',
    text => 'Hello <* a *>',
);

is( 
    $template->fill(callsign), 
    'Hello alpha', 
    'processed template with custom style for default tags'
);

$template = TEMPLATE->new(
    tagset => [
        overline => {
            type  => 'inline',
            style => '[* *]',
            
        },
    ],
    tags => '<* *>',
    text => 'Hello <* a *>.  Hello [* b *]',
);

is( 
    $template->fill(callsign), 
    'Hello alpha.  Hello bravo', 
    'processed template with custom default and additional tag style'
);

#print $template->scanner->tagset->dump;

1;
