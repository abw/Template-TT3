#============================================================= -*-perl-*-
#
# t/commands/wrapper.t
#
# Test script for the 'wrapper' command.
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
    tests       => 5,
    debug       => 'Template::TT3::Tag',
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

-- test wrapper on pre-defined block --
[? COMMANDS wrapper -?]
%% block foo "[CONTENT]$content[/CONTENT]";
[% wrapper foo "Hello World" %]
-- expect -- 
[CONTENT]Hello World[/CONTENT]

-- test WRAPPER on pre-defined block --
[? COMMANDS WRAPPER -?]
%% block foo "[CONTENT]$content[/CONTENT]";
[% WRAPPER foo "Hello World" %]
-- expect -- 
[CONTENT]Hello World[/CONTENT]

-- test WRAPPER on post-defined block --
[? COMMANDS { WRAPPER => 'wrapper' } -?]
[% WRAPPER foo "Hello Badger" %]
%% block foo "[CONTENT]$content[/CONTENT]";
-- expect -- 
[CONTENT]Hello Badger[/CONTENT]

-- test wrap on block with dotted/slashed name --
[? COMMANDS wrapper as wrap -?]
[% wrap foo/bar/baz.tt3 "Hello $r.ucfirst"; -%]
%% block foo/bar/baz.tt3 "[CONTENT]$content[/CONTENT]";
-- expect -- 
[CONTENT]Hello Romeo[/CONTENT]

-- test wrap as a side-effect --
[? COMMANDS wrapper as wrap -?]
[% "Hello $j.ucfirst" wrap foo/bar/baz.tt3  -%]
%% block foo/bar/baz.tt3 "[CONTENT]$content[/CONTENT]";
-- expect -- 
[CONTENT]Hello Juliet[/CONTENT]

