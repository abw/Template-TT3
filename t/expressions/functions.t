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
    tests   => 23,
    debug   => 'Template::TT3::Template',
    args    => \@ARGV,
    import  => 'test_expect callsign';

use Template::TT3::Type::Params 'PARAMS';
use Template::TT3::Utils 'tt_args hashlike';
use Badger::Debug ':dump';

our $vars = {
    %{ callsign() },
    
    perl_posit => sub {
        my @args = @_;
        return main->dump_data_inline(\@args);
    },

    perl_named => sub {
        my $params = @_ == 1 && ref $_[0] eq 'HASH' ? shift : { @_ };
        return main->dump_data_inline($params);
    },

    perl_tt => sub {
        my $params = @_ == 1 && hashlike $_[0] ? shift : { @_ };
        return main->dump_data_inline($params);
    },
    
    listsub => sub {
        my ($params, @args) = tt_args(@_);
#        my @args   = @_;
#        my $params = pop @args
#            if @args && ref $args[-1] eq 'HASH';
            
        my @params = $params
            ? main->dump_data_inline($params)
            : (); 
        
        my $list = [ 10, 20, 30, 'ARGS->', @args, 'PARAMS->', @params ];
        return wantarray
            ? @$list
            :  $list;
    },

    abc_hash => sub {
        return { x => 10, y => 20, z => 30 };
    },
};

test_expect(
    block     => 1,
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test code type --
%% listsub.type
-- expect --
Code

-- test explicit function call to dotop --
%% listsub().join
-- expect --
10 20 30 ARGS-> PARAMS->


#-----------------------------------------------------------------------
# Perl subroutine expecting positional arguments
#-----------------------------------------------------------------------

-- test perl positional with arguments --
%% perl_posit(a, 10, b, 20)
-- expect --
[ alpha, 10, bravo, 20 ]

-- test perl positional with arrows --
%% perl_posit(a => 10, b => 20)
-- expect --
[ a, 10, b, 20 ]

-- test perl positional with equals --
%% perl_posit(a = 10, b = 20)
-- expect --
[ { a => 10, b => 20 } ]

-- test perl positional with hashed arrows --
%% perl_posit({ a => 10, b => 20 })
-- expect --
[ { a => 10, b => 20 } ]

-- test perl positional with hashed equals --
%% perl_posit({ a = 10, b = 20 })
-- expect --
[ { a => 10, b => 20 } ]


#-----------------------------------------------------------------------
# Perl subroutine expecting named parameters
#-----------------------------------------------------------------------

-- test perl named with arguments --
%% perl_named(a, 10, b, 20)
-- expect --
{ alpha => 10, bravo => 20 }

-- test perl named with arrows --
%% perl_named(a => 10, b => 20)
-- expect --
{ a => 10, b => 20 }

-- test perl named with equals --
-- skip doesn't work when params are blessed object --
%% perl_named(a = 10, b = 20)
-- expect --
{ a => 10, b => 20 }

-- test perl named with hashed arrows --
%% perl_named({ a => 10, b => 20 })
-- expect --
{ a => 10, b => 20 }

-- test perl named with hashed equals --
%% perl_named({ a = 10, b = 20 })
-- expect --
{ a => 10, b => 20 }


#-----------------------------------------------------------------------
# Perl subroutine expecting named parameters as a hash or TT params
#-----------------------------------------------------------------------

-- test perl tt params with arguments --
%% perl_tt(a, 10, b, 20)
-- expect --
{ alpha => 10, bravo => 20 }

-- test perl tt params with arrows --
%% perl_tt(a => 10, b => 20)
-- expect --
{ a => 10, b => 20 }

-- test perl tt params with equals --
%% perl_tt(a = 10, b = 20)
-- expect --
{ a => 10, b => 20 }

-- test perl tt params with hashed arrows --
%% perl_tt({ a => 10, b => 20 })
-- expect --
{ a => 10, b => 20 }

-- test perl tt params with hashed equals --
%% perl_tt({ a = 10, b = 20 })
-- expect --
{ a => 10, b => 20 }



#-----------------------------------------------------------------------
# Calling Perl subroutines in list context
#-----------------------------------------------------------------------

-- test fat arrow --
%% [ 'merged' @listsub( a => 50 ) ].join
-- expect --
merged 10 20 30 ARGS-> a 50 PARAMS->

-- test assignment arrow --
%% [ 'merged' @listsub( a = 50 ) ].join
-- expect --
merged 10 20 30 ARGS-> PARAMS-> { a => 50 }

-- test merge list without parens --
%% [ 'merged' @listsub ].join
-- expect --
merged 10 20 30 ARGS-> PARAMS->

-- test merge list with parens --
%% [ 'merged' @listsub() ].join
-- expect --
merged 10 20 30 ARGS-> PARAMS->

-- test merge list with extra arguments --
%% [ 'merged' @listsub(40 50) ].join
-- expect --
merged 10 20 30 ARGS-> 40 50 PARAMS->

-- test merge list with fat arrow --
%% [ 'merged' @listsub( a => 50 ) ].join
-- expect --
merged 10 20 30 ARGS-> a 50 PARAMS->


