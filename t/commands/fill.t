#============================================================= -*-perl-*-
#
# t/commands/fill.t
#
# Test script for the 'fill' command.
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
    tests       => 15,
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


#-----------------------------------------------------------------------
# filling blocks
#-----------------------------------------------------------------------

-- test fill on pre-defined block --
%% block foo 'This is Foo';
%% fill foo
-- expect -- 
This is Foo

-- test fill on post-defined block --
%% fill bar
%% block bar 'This is Bar';
-- expect -- 
This is Bar

-- test fill on block with dotted/slashed name --
%% fill foo/bar/baz.tt3
%% block foo/bar/baz.tt3 'This is foo/bar/baz.tt3';
-- expect -- 
This is foo/bar/baz.tt3

-- test fill on 'quoted' block --
%% block wiz 'This is wiz, a is ' ~ a;
%% fill 'wiz'
-- expect --
This is wiz, a is alpha

-- test fill on "quoted" block --
%% block wiz_alpha 'This is wiz_alpha, a is ' ~ a;
%% fill "wiz_alpha"; "\n"
-- expect --
This is wiz_alpha, a is alpha

-- test fill on "quoted" block with embedded variable --
%% block wiz_alpha 'This is wiz_alpha, a is ' ~ a;
%% fill "wiz_$a"
-- expect --
This is wiz_alpha, a is alpha



#-----------------------------------------------------------------------
# filling blocks in nested contexts
#-----------------------------------------------------------------------

-- test fill block in with --
[%  block a_is "a is $a";
    fill a_is;
    "\n"
    fill a_is with a=b
%]
-- expect --
a is alpha
a is bravo

-- test fill block in just --
[%  block b_is "b is $b";
    fill b_is;
    "\n"
    fill b_is just b=c
%]
-- expect --
b is bravo
b is charlie


#-----------------------------------------------------------------------
# filling external templates
#-----------------------------------------------------------------------

-- test fill on external template --
%% fill hello.tt3
-- expect --
Hello World!

-- test fill on external template with slashed and dotted name --
%% fill foo/bar.tt3
-- expect --
This is the foo/bar.tt3 template

-- test fill on external template with params --
%% with name='Badger' fill hello.tt3 
-- expect --
Hello Badger!

-- test fill on external template with params in side-effect --
%% fill hello.tt3 with name='Mushroom'
-- expect --
Hello Mushroom!

-- test fill on external template just params in side-effect --
%% fill hello.tt3 just name='Snake'
-- expect --
Hello Snake!

-- test fill foo .tt3 --
%% fill foo .tt3
-- error -- 
TT3 resource error at line 1 of "fill foo .tt3" test:
    Error: Requested template resource not found: foo
   Source: %% fill foo .tt3
                   ^ here

# NOTE: this is broken because we now do parse_infix() on the right of 
# the 'fill'.  This is required for us to be able to write: fill foo with x=10
# However, the dotop consumes <fill foo> as the expression on the left,
# then tries to make it a variable and do a literal .tt3 on it.  Need to
# have a lhs_can_dotop() assertion that the dotop calls on the LHS.  Similar
# to the way assignment must work, I guess.


-- test fill $a --
-- skip not supported yet --
%% fill $a
-- expect --
TODO: fill alpha
