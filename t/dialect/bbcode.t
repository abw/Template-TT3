#============================================================= -*-perl-*-
#
# t/dialect/bbcode.t
#
# Test script for a custom BBCode dialect.  Note that this is testing 
# the ability to create and use a custom dialect.  The dialect itself is 
# meant to be illustrative and does not implement the full BBCode 
# specification in any shape or form.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib        => '../../lib lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug   => 'Template::TT3::Templates',
    args    => \@ARGV,
    tests   => 3;

my $tdir = Bin->dir('templates');


#-----------------------------------------------------------------------
# test the BBCode dialect
#-----------------------------------------------------------------------

use Template3;

my $tt3 = Template3->new(
    dialect => 'BBCode',
);

is( 
    $tt3->fill( text => 'This is [b]bold[/b] and this is [i]italic[/i]' ),
    'This is <b>bold</b> and this is <i>italic</i>',
    'BBCode dialect transformed text'
),



#-----------------------------------------------------------------------
# test a templates provider with two dialects in different paths
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    template_path => [
        { 
            path    => $tdir->dir('tt3'),
            dialect => 'TT3',
        },
        { 
            path    => $tdir->dir('bbcode'),
            dialect => 'BBCode',
        }
    ],
);

ok( $tt3, 'created engine with two dialects' );
my $output = $tt3->fill(
    file => 'hello.tt3',
    data => { name => 'Badger' }
);
chomp $output;
is( 
    $output, 
    "Hello Badger\nThis is <b>bold</b>\nThis is <i>italic</i>",
    "processed template with two dialects"
);
