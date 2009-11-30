#============================================================= -*-perl-*-
#
# t/parser/errors.t
#
# Test reporting of parse errors.
#
# Run with '-h' option for help with command line arguments.
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
    debug  => 'Template::TT3::Scanner Template::TT3::Tag',
    args   => \@ARGV,
    import => 'test_expect callsign';

test_expect(
    verbose    => 1,
    debug      => $DEBUG,
    variables  => callsign,
);

__DATA__

-- test missing unary operand error --
[% not %]
-- error --
TT3 syntax error at line 1 of "missing unary operand error" test:
    Error: Missing expression for 'not'.  Got '%]'
   Source: [% not %]
                  ^ here

-- test missing binary operand --
[% a + %]
-- error --
TT3 syntax error at line 1 of "missing binary operand" test:
    Error: Missing expression for '+'.  Got '%]'
   Source: [% a + %]
                  ^ here

-- test multi-line statement --
[% a + 
   b + 
   c + ^^^   # hello world! %]
-- error --
TT3 syntax error at line 3 of "multi-line statement" test:
    Error: Unexpected token: ^^^   # hello world! %]
   Source:    c + ^^^   # hello world! %]
                  ^ here

-- test error at start of string --
[% "$oops" %]
-- error --
TT3 undefined data error at line 1 of "error at start of string" test:
    Error: Undefined value returned by expression: oops
   Source: [% "$oops" %]
                ^ here

-- test error in string --
[% "blah$oops" %]
-- error --
TT3 undefined data error at line 1 of "error in string" test:
    Error: Undefined value returned by expression: oops
   Source: [% "blah$oops" %]
                    ^ here

-- test error at end of string --
[% "blah $a $b $c $a.length $b.length $yak" %]
-- error --
TT3 undefined data error at line 1 of "error at end of string" test:
    Error: Undefined value returned by expression: yak
   Source: [% "blah $a $b $c $a.length $b.length $yak" %]
                                                  ^ here
