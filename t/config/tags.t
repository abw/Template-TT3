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

use Template::TT3::Test 
    tests   => 2,
    debug   => 'Template::TT3::Tagset Template::TT3::Scanner',
    args    => \@ARGV,
    import  => 'callsign :all';

use Template3;
use Badger::Debug ':debug :dump';

my ($tt3, $template, $input, $output);

#-----------------------------------------------------------------------
# create engine, fetch template, fill it
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    tags => '<* *>',
);    
ok( $tt3, 'created TT3 engine with custom tags' );

$template = $tt3->template(
    text => 'Hello <* a *>',
);
ok( $template, 'created text template' );

$output = $template->fill( callsign );
is( 
    $output, 
    'Hello alpha', 
    'processed template with custom style for default tags'
);


#-----------------------------------------------------------------------
# all in one fill()
#-----------------------------------------------------------------------

$output = $tt3->fill(
    text => 'Hello <* b *>',
    data => callsign(),
);

is( 
    $output, 
    'Hello bravo', 
    'processed template via fill()'
);


#-----------------------------------------------------------------------
# all in one process()
#-----------------------------------------------------------------------

$output = '';
$input = 'Hello <* c *>', 

ok( 
    $tt3->process(\$input, callsign(), \$output), 
    'processed template via process()',
);

is( 
    $output, 
    'Hello charlie', 
    'got output from process()'
);


__END__

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
