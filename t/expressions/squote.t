#============================================================= -*-perl-*-
#
# t/expressions/squote.t
#
# Test single quoted strings.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib';
    
use Template::TT3::Test
    tests  => 6,
    debug  => 'Template::TT3::Tag',
    args   => \@ARGV,
    import => 'test_expect callsign';
    
test_expect(
    block     => 1,             # treat each test as a single block
    debug     => $DEBUG,
    variables => callsign,
);

__DATA__

-- test simple single quoted string --
%% 'This is a single quoted string'
-- expect --
This is a single quoted string

-- test single quoted string with literal newline --
[% 'This is a single quoted string with
literal newlines and spaces embedded' %]
-- expect --
This is a single quoted string with
literal newlines and spaces embedded

-- test single quoted string with escaped quotes --
[% 'This is a single quoted string with
escaped \'single quotes\' in it' %]
-- expect --
This is a single quoted string with
escaped 'single quotes' in it

-- test single quoted string with escaped backslash --
[% 'The only other character that might require escaping is 
the backslash character itself when it appears right at
the end of a single quoted string like this: \\' %]
-- expect --
The only other character that might require escaping is 
the backslash character itself when it appears right at
the end of a single quoted string like this: \

-- test single quoted string with other escapes --
[% 'If a backslash appears before \any\ other character other
than \\ or \' then it will be left intact' %]
-- expect --
If a backslash appears before \any\ other character other
than \ or ' then it will be left intact

-- test single quoted string with crappy dos path --
[% 'That means you can single quote MS paths like
C:\Program Files\Template Toolkit\ and not have to 
worry about escaping every backslash' %]
-- expect --
That means you can single quote MS paths like
C:\Program Files\Template Toolkit\ and not have to 
worry about escaping every backslash
