package Template::TT3::Grammar::TT3;

use utf8;
use Template::TT3::Elements::Core;
use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Grammar';

# TODO: decide what we're going to do with ops that can work both ways, e.g.
# %foo and foo % bar

# We're lazy, so we rely on Badger::Factory (the base class of T::Elements
# which in turn is the base class of T::Grammar) to convert a simple string 
# like "foo_bar" into the appropriate T::Element::FooBar module name.  We
# use dots to delimit namespaces, e.g. 'numeric.add' is expanded to 
# T::Element::Numeric::Add.  However, because we're *really* lazy and can't
# be bothered quoting lots of strings like 'numeric.add' (they have to be
# quoted because the dot can't be bareworded on the left of =>) we define
# a bunch of prefixes that get pre-expanded when the symbol table is imported.
# e.g 'num_add' becomes 'numeric.add' becomes 'T::Element::Numeric::Add'

our $PREFIXES = {
    cmd_  => 'command.',
    num_  => 'number.',
    txt_  => 'text.',
    sig_  => 'sigil.',
    var_  => 'variable.',
    bool_ => 'boolean.',
};
    

our $SYMBOLS  = [
#   [ token => element_name => left_precedence, right_precedence ]

    # variable sigils and other super-duper high precedence operators
    [ '$'       => sig_item         =>   0, 350 ],      # $foo
    [ '@'       => sig_list         =>   0, 350 ],      # @foo
#   [ '%'       => percent          =>   0, 350 ],      # %foo
    [ '.'       => dot              => 340,   0 ],      # foo.bar
    
    # ++/-- unary prefix/postfix self-modification operators
    [ '++'      => num_inc          => 295, 295 ],      # foo++, ++foo
    [ '--'      => num_dec          => 295, 295 ],      # foo--, --foo
    
    # mathematical operators
    [ '**'      => num_power        => 290,   0 ],      # foo ** 3
    [ '+'       => num_plus         => 275, 285 ],      # foo + bar, +foo
    [ '-'       => num_minus        => 275, 285 ],      # foo - bar, -foo
    [ '*'       => num_multiply     => 280,   0 ],      # foo * bar
    [ '/'       => num_divide       => 280,   0 ],      # foo / bar
    [ '%'       => num_percent      => 280, 350 ],      # foo % bar, %bar
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
    [ '='       => assign           => 220,   0 ],      # foo = bar
    [ '=>'      => fat_arrow        => 220,   0 ],      # foo => bar
    [ '~='      => txt_combine_set  => 220,   0 ],      # foo ~= bar
    [ '+='      => num_add_set      => 220,   0 ],      # foo += bar
    [ '-='      => num_sub_set      => 220,   0 ],      # foo -= bar
    [ '*='      => num_mul_set      => 220,   0 ],      # foo *= bar
    [ '/='      => num_div_set      => 220,   0 ],      # foo /= bar
    [ '&&='     => bool_and_set     => 220,   0 ],      # foo &&= bar
    [ '||='     => bool_or_set      => 220,   0 ],      # foo ||= bar
    [ '!!='     => bool_nor_set     => 220,   0 ],      # foo !!= bar
                                
    # low precedence short-circuiting logical operators
    [ 'not'     => bool_not         => 0,   215 ],      # not foo
    [ 'and'     => bool_and         => 210,   0 ],      # foo and bar
    [ 'or'      => bool_or          => 205,   0 ],      # foo or bar
    [ 'nor'     => bool_nor         => 205,   0 ],      # foo nor bar
                                
    # directive keywords    
    [ 'do'      => cmd_do           => 150,   0 ],
    [ 'as'      => cmd_as           => 150,   0 ],
    [ 'is'      => cmd_is           => 150,   0 ],
    [ 'raw'     => cmd_raw          => 150,   0 ],
    [ 'if'      => cmd_if           => 150,   0 ],
    [ 'for'     => cmd_for          => 150,   0 ],
    [ 'fill'    => cmd_fill         => 150,   0 ],
    [ 'end'     => end              =>   0,   0 ],
    [ 'block'   => cmd_block        => 150,   0 ],

#    [ "${COMMAND}::With"        => 150,   0, 'with', 'end' ],
#    [ "${COMMAND}::Block"       =>   0,   0, 'block', 'end' ],
#    [ "${COMMAND}::Dump"        =>   0,   0, 'dump' ],
#    [ "${COMMAND}::Use"         =>   0,   0, 'use' ],
#    [ "${COMMAND}::Tags"        =>   0,   0, 'TAGS' ],
                                
    # grouping constructs
    [ '('       => parens           =>   0,   0 ],
    [ '['       => list             =>   0,   0 ],
    [ '{'       => hash             =>   0,   0 ],
    [ ')'       => terminator       =>   0,   0 ],
    [ ']'       => terminator       =>   0,   0 ],
    [ '}'       => terminator       =>   0,   0 ],

#    [ [']', ')', '}']
#         => terminator     =>   0,   0 ],

    
    # Other punctuation marks
    [ ','       => separator        =>   0,   0 ],
    [ ';'       => delimiter        =>   0,   0 ],
    [ ':'       => terminator       =>   0,   0 ],
];
