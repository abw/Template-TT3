#============================================================= -*-perl-*-
#
# t/commands/as.t
#
# Test script for the 'as' command.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use lib '/home/abw/projects/badger/lib';                    # abw testing
#use Badger::Debug modules => 'Badger::Class::Config';       # abw testing

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    tests   => 6,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);


__DATA__

-- test alpha --
%% as content a; 'content: ' content
-- expect -- 
content: alpha

-- test bravo --
%% b as content; 'content: ' content
-- expect -- 
content: bravo

-- test charlie delta echo --
[%
    as content; 
        c ' ' d ' ' e; 
    end; 
    'content: ' content
%]
-- expect -- 
content: charlie delta echo 

-- test foxtrot golf --
[%
    as content {
        f ' ' g
    }
    'content: ' content
%]
-- expect -- 
content: foxtrot golf

-- test echo foxtrot golf --
%% a is { e f g } a
-- expect -- 
echofoxtrotgolf

-- test hotel --
[%
    content = as middle {
        h
    }
    'content: ' content '  middle: ' middle
%]
-- expect --
content: hotel  middle: hotel


