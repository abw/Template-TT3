#============================================================= -*-perl-*-
#
# t/parser/strings.t
#
# Test the Template::Parser's ability to recognise strings.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
#use Badger::Debug modules => 'Template::TT3::Tag';
use Template::TT3::Test::Parser 
#    skip   => 'Not working yet',
    tests  => 9,
    debug  => 'Template::TT3::Tag Template::TT3::Scanner',
    args   => \@ARGV,
    import => 'test_parser';


test_parser(
    debug => $DEBUG,
);

__DATA__

-- test empty single quoted string --
''
-- expect --
<squote:''>

-- test empty single with trailing text  --
''hello world
-- expect --
<squote:''>
<variable:hello>
<variable:world>

-- test single quoted string --
'hello'
-- expect --
<squote:'hello'>

-- test single with doubles inside --
'"hello" world'
-- expect --
<squote:'"hello" world'>

-- test single with trailing text --
'hello' badger
-- expect --
<squote:'hello'>
<variable:badger>

-- test single with escape single quotes --
'foo \'bar\' baz'
-- expect --
<squote:'foo \'bar\' baz'>

-- test single with backslashes --
'foo 10\3 bar'
-- expect --
<squote:'foo 10\3 bar'>

-- test single with escaped backslashes --
'foo\\bar\\baz'
-- expect --
<squote:'foo\\bar\\baz'>

-- test single with other slashes --
'foo\nbar\tbaz\/\/xyz'
-- expect --
<squote:'foo\nbar\tbaz\/\/xyz'>

