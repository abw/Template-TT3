#============================================================= -*-perl-*-
#
# t/expressions/functions.t
#
# Test script for function calls.
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
    tests   => 8,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

use Template::TT3::Utils 'tt_args';

our $vars = {
    %{ callsign() },
    
    listsub => sub {
        my ($params, @args) = tt_args(@_);
        my @params = $params
            ? '{ ' . join(', ', map { "$_ => $params->{ $_ }" } sort keys %$params) . ' }'
            : (); 
        
        my $list = [ 10, 20, 30, @args, @params ];
        return wantarray
            ? @$list
            :  $list;
    },

    abc_hash => sub {
        return { x => 10, y => 20, z => 30 };
    },
};

test_expressions(
    block     => 1,
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test code type --
listsub.type
-- expect --
Code

-- test explicit function call to dotop --
listsub().join
-- expect --
10 20 30

-- test fat arrow --
[ 'merged' @listsub( a => 50 ) ].join
-- expect --
merged 10 20 30 a 50

-- test assignment arrow --
[ 'merged' @listsub( a = 50 ) ].join
-- expect --
merged 10 20 30 { a => 50 }


-- test merge list without parens --
[ 'merged' @listsub ].join
-- expect --
merged 10 20 30

-- test merge list with parens --
[ 'merged' @listsub() ].join
-- expect --
merged 10 20 30

-- test merge list with extra arguments --
[ 'merged' @listsub(40 50) ].join
-- expect --
merged 10 20 30 40 50

-- test merge list with fat arrow --
[ 'merged' @listsub( a => 50 ) ].join
-- expect --
merged 10 20 30 a 50


