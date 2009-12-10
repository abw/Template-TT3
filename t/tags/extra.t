#============================================================= -*-perl-*-
#
# t/tags/extra.t
#
# Test script for the 'tagset' config option which allows you to define
# additional tags.
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

my ($tt3, $input, $expect, $output);

#-----------------------------------------------------------------------
# create engine, fetch template, fill it
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    tagset => [
        picture => {
            type    => 'replace',
            start   => '<picture:',
            end     => '>',
            replace => sub {
                my ($self, $text) = @_;
                return qq{<img src="/images/pictures/$text">};
            }
        }
    ]
);    
ok( $tt3, 'created TT3 engine with extra picture tag' );

$input =<<EOF;
Hello [% name or 'World' %]!
<picture:hello.png>
EOF

$expect =<<EOF;
Hello Badger!
<img src="/images/pictures/hello.png">
EOF

$output = $tt3->fill(
    text => $input,
    data => { name => 'Badger' },
);

is( $output, $expect, 'processed template with extra picture tag' );
