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
    tests  => 2,
    debug  => 'Template::TT3::Scanner Template::TT3::Tag',
    args   => \@ARGV,
    import => 'test_expect';

test_expect(
    full_error => 1,
    debug      => $DEBUG,
);

__DATA__

-- test missing binary operand --
[% a + %]
-- error --
TT3 Syntax Error at line 1 of "missing binary operand" test: Missing expression for '+'.  Got '%]'
Source: [% a + %]
               ^ here

-- test multi-line statement --
[% a + 
   b + 
   c + ^^^   # hello world! %]
-- error --
TT3 Syntax Error at line 3 of "multi-line statement" test: Unexpected token: ^^^   # hello world! %]
Source:    c + ^^^   # hello world! %]
               ^ here
