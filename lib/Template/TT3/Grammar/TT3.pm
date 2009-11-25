package Template::TT3::Grammar::TT3;

use utf8;
use Template::TT3::Elements::Core;
use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Grammar';

# These are the command keywords that we recognise
our $COMMANDS = 'as is do dot sub block with just
                 for if else elsif fill 
                 encode decode raw';

our $SYMBOLS  = [
#   [ token => element_name => left_precedence, right_precedence ]

    # variable sigils and other super-duper high precedence operators
    [ '$'       => sig_item         =>   0, 350 ],      # $foo
    [ '@'       => sig_list         =>   0, 350 ],      # @foo
    [ '%'       => sig_hash         =>   0, 350 ],      # %foo
    [ '.'       => op_dot           => 340,   0 ],      # foo.bar
    
    # ++/-- unary prefix/postfix self-modification operators
    [ '++'      => num_inc          => 295, 295 ],      # foo++, ++foo
    [ '--'      => num_dec          => 295, 295 ],      # foo--, --foo
    
    # mathematical operators
    [ '**'      => num_power        => 290,   0 ],      # foo ** 3
    [ '+'       => num_plus         => 275, 285 ],      # foo + bar, +foo
    [ '-'       => num_minus        => 275, 285 ],      # foo - bar, -foo
    [ '*'       => num_multiply     => 280,   0 ],      # foo * bar
    [ '/'       => num_divide       => 280,   0 ],      # foo / bar
    [ qr/\s%\s/ => num_percent      => 280,   0 ],      # foo % bar
    [ div       => num_div_int      => 280,   0 ],      # foo div bar
    [ mod       => num_modulus      => 280,   0 ],      # foo mod bar
    
    # text concatentation operator
    [ '~'       => txt_squiggle     => 270, 270 ],      # foo ~ bar, ~ foo

    # NOTE: Perl6 has cmp and <=> here

    # numerical comparisons operators
    # NOTE: TT2 treats == as a string-based comparison - needs resolving
    [ '=='      => num_equal        => 260,   0 ],      # foo == bar
    [ '!='      => num_not_equal    => 260,   0 ],      # foo != bar
    [ '<'       => num_less_than    => 260,   0 ],      # foo < bar
    [ '>'       => num_more_than    => 260,   0 ],      # foo > bar
    [ '<='      => num_less_equal   => 260,   0 ],      # foo <= bar
    [ '>='      => num_more_equal   => 260,   0 ],      # foo >= bar
    [ '<=>'     => num_compare      => 260,   0 ],      # foo <=> bar

    # Text comparison operators. 
    [ 'eq'      => txt_equal        => 260,   0 ],      # foo == bar
    [ 'ne'      => txt_not_equal    => 260,   0 ],      # foo != bar
    [ 'lt'      => txt_less_than    => 260,   0 ],      # foo < bar
    [ 'gt'      => txt_more_than    => 260,   0 ],      # foo > bar
    [ 'le'      => txt_less_equal   => 260,   0 ],      # foo <= bar
    [ 'ge'      => txt_more_equal   => 260,   0 ],      # foo >= bar
    [ 'cmp'     => txt_compare      => 260,   0 ],      # foo <=> bar

    # boolean logic operators
    [ '!'       => bool_not         =>   0, 285 ],      # !foo
    [ '&&'      => bool_and         => 255,   0 ],      # foo && bar
    [ '||'      => bool_or          => 250,   0 ],      # foo || bar
    
    # TODO: '!!' as a prefix operator:   !!some_var_that_may_be_undefined
    [ '!!'      => bool_nor         => 250,   0 ],      # foo !! bar

    [ '..'      => num_range        => 240,   0 ],      # 1 .. 91
    [ 'to'      => num_to           => 240,   0 ],      # 1 to 91 by 10      # TODO: by
    [ 'by'      => num_by           => 240,   0 ],      # 1 to 91 by 10      # TODO: by
    
    [ '?'       => question         => 230,   0 ],      # foo ? bar : baz
#    [ ':'       => terminator       =>   0,   0 ],      # foo ? bar : baz       # TODO: terminator

    # this used to be above ? : but I think it's better here so that 
    # something like a -> a > 10 ? "big" : "small" is parsed as 
    # a -> ((a > 10) ? "big" : "small")
    [ '->'      => arrow            => 230,   0 ],      # a -> a + 1

    # binary assignment operators
    [ '='       => op_assign        => 200,   0 ],      # foo = bar
    [ '=>'      => op_pair          => 200,   0 ],      # foo => bar
    [ '~='      => txt_combine_set  => 200,   0 ],      # foo ~= bar
    [ '+='      => num_add_set      => 200,   0 ],      # foo += bar
    [ '-='      => num_sub_set      => 200,   0 ],      # foo -= bar
    [ '*='      => num_mul_set      => 200,   0 ],      # foo *= bar
    [ '/='      => num_div_set      => 200,   0 ],      # foo /= bar
    [ '&&='     => bool_and_set     => 200,   0 ],      # foo &&= bar
    [ '||='     => bool_or_set      => 200,   0 ],      # foo ||= bar
    [ '!!='     => bool_nor_set     => 200,   0 ],      # foo !!= bar
                                
    # low precedence short-circuiting logical operators
    [ 'not'     => bool_not         => 0,   190 ],      # not foo
    [ 'and'     => bool_and         => 180,   0 ],      # foo and bar
    [ 'or'      => bool_or          => 170,   0 ],      # foo or bar
    [ 'nor'     => bool_nor         => 170,   0 ],      # foo nor bar
                                
    # grouping constructs...
    [ '('       => con_parens       =>   0,   0 ],
    [ '['       => con_list         =>   0,   0 ],
    [ '{'       => con_hash         =>   0,   0 ],
    
    # ...and their respective terminators
    [ ')'       => terminator       =>   0,   0 ],
    [ ']'       => terminator       =>   0,   0 ],
    [ '}'       => terminator       =>   0,   0 ],

    # Other punctuation marks
    [ ','       => separator        =>   0,   0 ],
    [ ';'       => delimiter        =>   0,   0 ],
    [ ':'       => terminator       =>   0,   0 ],
    [ '#'       => terminator       =>   0,   0 ],
    
    # One token to end them all and in the darkness bind them
    [ 'end'     => end              =>   0,   0 ],
];


1;
