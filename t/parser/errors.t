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
    debug  => 'Template::TT3::Scanner Template::TT3::Tag',
    args   => \@ARGV,
    tests  => 7,
    import => 'test_expect callsign';

my $vars = {
    %{ callsign() },
    null => undef,
};

test_expect(
    verbose    => 1,
    debug      => $DEBUG,
    variables  => $vars,
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
TT3 data error at line 1 of "error at start of string" test:
    Error: Missing value: oops
   Source: [% "$oops" %]
                ^ here

-- test error in string --
[% "blah$oops" %]
-- error --
TT3 data error at line 1 of "error in string" test:
    Error: Missing value: oops
   Source: [% "blah$oops" %]
                    ^ here

-- test error at end of string --
[% "blah $a $b $c $a.length $b.length $yak" %]
-- error --
TT3 data error at line 1 of "error at end of string" test:
    Error: Missing value: yak
   Source: [% "blah $a $b $c $a.length $b.length $yak" %]
                                                  ^ here

-- test undefined data --
%% null
-- error --
TT3 data error at line 1 of "undefined data" test:
    Error: Undefined value: null
   Source: %% null
              ^ here
