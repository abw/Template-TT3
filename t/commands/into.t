#============================================================= -*-perl-*-
#
# t/commands/into.t
#
# Test script for the 'into' command.
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
    tests       => 9,
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

-- test into on pre-defined block --
%% block foo "[CONTENT]$content[/CONTENT]";
%% into foo "Hello World"
-- expect -- 
[CONTENT]Hello World[/CONTENT]

-- test into on post-defined block --
%% into foo "Hello Badger"
%% block foo "[CONTENT]$content[/CONTENT]";
-- expect -- 
[CONTENT]Hello Badger[/CONTENT]

-- test fill on block with dotted/slashed name --
%% into foo/bar/baz.tt3 "Hello $r.ucfirst";
%% block foo/bar/baz.tt3 "[CONTENT]$content[/CONTENT]";
-- expect -- 
[CONTENT]Hello Romeo[/CONTENT]

-- test into as side-effect --
%% block foo "[FOO:$content]"
%% 'Hello' into foo
-- expect --
[FOO:Hello]

-- test into as double side-effect --
%% block foo "[FOO:$content]"
%% 'baz' into bar into foo
%% block bar "[BAR:$content]"
-- expect --
[FOO:[BAR:baz]]

-- test into on external template --
%% "Hello World!\n" into wrapper/html.tt3
-- expect --
<html>
  <head>
    <title>Default Title</title>
  </head>
  <body>
Hello World!
  </body>
</html>

-- test into on external template with extra vars --
[%  "Hello World!\n" 
        into wrapper/html.tt3 
            with title='Greetings, People of Earth'
%]
-- expect --
<html>
  <head>
    <title>Greetings, People of Earth</title>
  </head>
  <body>
Hello World!
  </body>
</html>

-- test into with undefined variable --
%%  "Hello Badger" into wrapper/message.tt3
-- error --
TT3 data error at line 1 of wrapper/message.tt3:
    Error: Missing value: status
   Source: <div class="message [% status %]">
                                  ^ here
-- test into with status defined --
%%  "Hello Badger\n" into wrapper/message.tt3 with status='success'
-- expect --
<div class="message success">
Hello Badger
</div>

