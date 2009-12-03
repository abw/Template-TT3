#============================================================= -*-perl-*-
#
# t/commands/slot.t
#
# Test script for the 'slot' command.
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
    lib         => '../../lib',
    Filesystem  => 'Bin';

use Template::TT3::Test 
    tests       => 7,
    debug       => 'Template::TT3::Template',
    args        => \@ARGV,
    import      => 'test_expect callsign';

test_expect(
    block       => 1,
    verbose     => 1,
    debug       => $DEBUG,
    variables   => callsign,
    config      => {
        template_path => Bin->dir('templates'),
    },
);


__DATA__

-- test top level slot --
%% slot header 'Default Header'
-- expect -- 
Default Header

-- test slot in block --
%% block foo { slot header 'Default Header' }
%% fill foo
-- expect -- 
Default Header

-- test slot in block --
%% block foo { slot header 'Default Header' }
%% fill foo
-- expect -- 
Default Header

-- test external template with default slots --
%% fill layout/site
-- expect --
[begin site layout]
This is the default header
This is the default content
This is the default footer
[end site layout]

-- test external template with custom slots --
%% fill layout/site
%% block header "This is the custom header\n"
%% block footer "This is the custom footer\n"
-- expect --
[begin site layout]
This is the custom header
This is the default content
This is the custom footer
[end site layout]

-- test external sub-layout template --
%% fill layout/product
-- expect --
[begin product layout]
[begin site layout]
This is the product header.  It cannot be changed.
This is the default product content
This is the product footer.  It cannot be changed.
[end site layout]
[end product layout]

-- test external sub-layout template with blocks --
%% fill layout/product
%% block header  "This is the custom header\n"
%% block content "This is the custom content\n"
%% block footer  "This is the custom footer\n"
-- expect --
[begin product layout]
[begin site layout]
This is the product header.  It cannot be changed.
This is the custom content
This is the product footer.  It cannot be changed.
[end site layout]
[end product layout]

