#============================================================= -*-perl-*-
#
# t/expressions/dquote.t
#
# Test double quoted strings.
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
    tests   => 10,
    debug   => 'Template::TT3::Tag',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

my $vars = {
    %{ callsign() },
    user => {
        name => 'Arthur Dent',
    },
};

test_expressions(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test simple double quoted string --
"This is a double quoted string"
-- expect --
This is a double quoted string

-- test double quoted string with literal newline --
-- block --
"This is a double quoted string with
a literal newline"
-- expect --
This is a double quoted string with
a literal newline


-- test embedded \n and \t --
"You can also use \n to encode newlines and \t for tabs"
-- expect --
You can also use 
 to encode newlines and 	 for tabs

-- test escaped quotes --
-- block --
"You can also use the backslash characters to escape
other \"double quotes\" inside the string"
-- expect --
You can also use the backslash characters to escape
other "double quotes" inside the string


-- test escaped backslashes --
-- block --
"Backslash characters can also escape themselves.  Say, if
you want a literal backslash and then an 'n' like this: \\n"
-- expect --
Backslash characters can also escape themselves.  Say, if
you want a literal backslash and then an 'n' like this: \n

-- test other backslashes --
-- block --
"If a backslash appears before \any\ other character other
than '\\', '\"', 'n' or 't' then it will be left intact.
Here\is\an\example\of\\that - note we *DO* need the extra
backslash before the 't' otherwise it would be interpreted
as a tab character"
-- expect --
If a backslash appears before \any\ other character other
than '\', '"', 'n' or 't' then it will be left intact.
Here\is\an\example\of\that - note we *DO* need the extra
backslash before the 't' otherwise it would be interpreted
as a tab character

-- test crappy dos paths --
-- block --
"That means you can double quote MS paths like
C:\Program Files\Template Toolkit\ and not have to 
worry about escaping every backslash"
-- expect --
That means you can double quote MS paths like
C:\Program Files\Template Toolkit\ and not have to 
worry about escaping every backslash

-- test embedded variables --
"Hello $a"
-- expect --
Hello alpha

-- test embedded dotop --
"Hello $user.name"
-- expect --
Hello Arthur Dent

-- test embedded dotops --
"Your name is $user.name.length characters long"
-- expect --
Your name is 11 characters long
