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
    bool_ => 'boolean.',
};
    

our $SYMBOLS  = [
    # [ $token, $name, $left_precedence, $right_precedence ]

    # variable sigils
    [ '$'   => dollar       =>   0, 350 ],      # $foo
    [ '@'   => at           =>   0, 350 ],      # @foo
#   [ '%'   => percent      =>   0, 350 ],      # %foo
    [ '.'   => dot          => 340,   0 ],      # foo.bar
    
    # ++/-- unary prefix/postfix self-modification operators
    [ '++' => num_inc           => 295, 295 ],      # foo++, ++foo
    [ '--' => num_dec           => 295, 295 ],      # foo--, --foo
    
    # ** binary power operator binds very tight
    [ '**' => num_power         => 290,   0 ],      # foo ** 3

    # other mathematical operators
    [ '+'  => num_plus          => 275, 285 ],      # foo + bar, +foo
    [ '-'  => num_minus         => 275, 285 ],      # foo - bar, -foo
    [ '*'  => star              => 280,   0 ],      # foo * bar
    [ '/'  => slash             => 280,   0 ],      # foo / bar
    [ '%'  => percent           => 280, 350 ],      # foo % bar, %bar
    [ div  => div               => 280,   0 ],      # foo div bar
    [ mod  => mod               => 280,   0 ],      # foo mod bar
    
    # text concatentation operator
    [ '~'  => txt_append        => 270,   0 ],      # foo ~ bar

    # NOTE: Perl6 has cmp and <=> here

    # numerical comparisons operators
    # NOTE: TT2 treats == as a string-based comparison - needs resolving
    [ '=='  => num_equal        => 260,   0 ],      # foo == bar
    [ '!='  => num_not_equal    => 260,   0 ],      # foo != bar
    [ '<'   => num_less_than    => 260,   0 ],      # foo < bar
    [ '>'   => num_more_than    => 260,   0 ],      # foo > bar
    [ '<='  => num_less_equal   => 260,   0 ],      # foo <= bar
    [ '>='  => num_more_equal   => 260,   0 ],      # foo >= bar
    [ '<=>' => num_compare      => 260,   0 ],      # foo <=> bar

    # Text comparison operators.  We use the same operator tokens as Perl 
    # does, but give them different token names to disambiguate them from 
    # the numerical comparison operators.
    [ 'eq'  => txt_equal        => 260,   0 ],      # foo == bar
    [ 'ne'  => txt_not_equal    => 260,   0 ],      # foo != bar
    [ 'lt'  => txt_less_than    => 260,   0 ],      # foo < bar
    [ 'gt'  => txt_more_than    => 260,   0 ],      # foo > bar
    [ 'le'  => txt_less_equal   => 260,   0 ],      # foo <= bar
    [ 'ge'  => txt_more_equal   => 260,   0 ],      # foo >= bar
    [ 'cmp' => txt_compare      => 260,   0 ],      # foo <=> bar

    # boolean logic operators
    [ '!'   => bool_not         =>   0, 285 ],      # !foo
    [ '&&'  => bool_and         => 255,   0 ],      # foo && bar
    [ '||'  => bool_or          => 250,   0 ],      # foo || bar
    [ '!!'  => bool_nor         => 250,   0 ],      # foo !! bar

    [ '..'  => num_range        => 240,   0 ],      # 1 .. 91
    [ 'to'  => num_to           => 240,   0 ],      # 1 to 91 by 10      # TODO: by
    [ 'by'  => num_by           => 240,   0 ],      # 1 to 91 by 10      # TODO: by
    
    [ '?'   => question         => 230,   0 ],      # foo ? bar : baz
    [ ':'   => colon            => 230,   0 ],      # foo ? bar : baz       # TODO: terminator

    # this used to be above ? : but I think it's better here so that 
    # something like a -> a > 10 ? "big" : "small" is parsed as 
    # a -> ((a > 10) ? "big" : "small")
    [ ['->', '→']                                   # we can do utf8!
            => arrow            => 230,   0 ],      # a -> a + 1

    # binary assignment operators
    [ '='   => assign           => 220,   0 ],      # foo = bar
    [ '=>'  => fat_arrow        => 220,   0 ],      # foo => bar
    [ '~='  => append_to        => 220,   0 ],      # foo ~= bar
    [ '+='  => num_add_eq       => 220,   0 ],      # foo += bar
    [ '-='  => num_sub_eq       => 220,   0 ],      # foo -= bar
    [ '*='  => num_mul_eq       => 220,   0 ],      # foo *= bar
    [ '/='  => num_div_eq       => 220,   0 ],      # foo /= bar
    [ '&&=' => bool_and_eq      => 220,   0 ],      # foo &&= bar
    [ '||=' => bool_or_eq       => 220,   0 ],      # foo ||= bar
    [ '!!=' => bool_nor_eq      => 220,   0 ],      # foo !!= bar
                                
    # low precedence short-circuiting logical operators
    [ 'not' => bool_not         => 0,   215 ],      # not foo
    [ 'and' => bool_and         => 210,   0 ],      # foo and bar
    [ 'or'  => bool_or          => 205,   0 ],      # foo or bar
    [ 'nor' => bool_nor         => 205,   0 ],      # foo nor bar
                                
    # directive keywords    
    [ 'do'  => cmd_do           => 150,   0 ],
    [ 'end' => cmd_end          =>   0,   0 ],
#    [ "${COMMAND}::For"         => 150,   0, 'for', 'in', 'end' ],
#    [ "${COMMAND}::With"        => 150,   0, 'with', 'end' ],
#    [ "${COMMAND}::Block"       =>   0,   0, 'block', 'end' ],
#    [ "${COMMAND}::Dump"        =>   0,   0, 'dump' ],
#    [ "${COMMAND}::Use"         =>   0,   0, 'use' ],
#    [ "${COMMAND}::Tags"        =>   0,   0, 'TAGS' ],
                                
    # grouping constructs
    [ '(' => lparen         =>   0,   0 ],
    [ ')' => rparen         =>   0,   0 ],
    [ '[' => lbracket       =>   0,   0 ],
    [ ']' => rbracket       =>   0,   0 ],
    [ '{' => lbrace         =>   0,   0 ],
    [ '}' => rbrace         =>   0,   0 ],
    
    # punctuation
    [ ',' => separator      =>   0,   0 ],
    [ ';' => terminator     =>   0,   0 ],
];
