#============================================================= -*-perl-*-
#
# t/expressions/files.t
#
# Test script for file handling
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib        => '../../lib',
    Filesystem => 'Bin';
    

use Template::TT3::Test 
    skip    => 'Temporary tests',
    tests   => 1,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    block     => 1,
    verbose   => 1,
    debug     => $DEBUG,
    variables => {
        dir => Bin,
    },
);

__DATA__

-- test files --
#%% "dir: $dir\n"; files = dir.files; files.size
-- expect --
#10ish
