#============================================================= -*-perl-*-
#
# t/engine/template3.t
#
# Test the Template3 module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug => 'Template3',
    args  => \@ARGV,
    tests => 1;

use Template3;

my $tdir = Bin->dir('templates');
my $tt3  = Template3->new( template_path => $tdir );
ok( $tt3, 'created template engine' );

# Input tests moved to input.t
# Output tests moved to output.t
# What else should be in here?  
