package Template::TT3::Grammar::TT3;

use utf8;
use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Grammar';

# TODO: decide what we're going to do with ops that can work both ways, e.g.
# %foo and foo % bar

our $SYMBOLS  = [
    # [ $token, $name, $left_precedence, $right_precedence ]

    # variable sigils
    [ '$'   => dollar       =>   0, 350 ],      # $foo
    [ '@'   => at           =>   0, 350 ],      # @foo
#    [ '%'   => percent      =>   0, 350 ],      # %foo
    [ '.'   => dot          => 340,   0 ],      # foo.bar
    
    # ++/-- unary prefix/postfix self-modification operators
    [ '++' => inc           => 295, 295 ],      # foo++, ++foo
    [ '--' => dec           => 295, 295 ],      # foo--, --foo
    
    # ** binary power operator binds very tight
    [ '**' => power         => 290,   0 ],      # foo ** 3

    # other mathematical operators
    [ '+'  => plus          => 275, 285 ],      # foo + bar, +foo
    [ '-'  => minus         => 275, 285 ],      # foo - bar, -foo
    [ '*'  => star          => 280,   0 ],      # foo * bar
    [ '/'  => slash         => 280,   0 ],      # foo / bar
    [ div  => div           => 280,   0 ],      # foo div bar
    [ '%'  => percent       => 280, 350 ],      # foo % bar, %bar
    [ mod  => mod           => 280,   0 ],      # foo mod bar
    
    # text concatentation operator
    [ '~'  => append        => 270,   0 ],      # foo ~ bar

    # NOTE: Perl6 has cmp and <=> here

    # numerical comparisons operators
    # NOTE: TT2 treats == as a string-based comparison - needs resolving
    [ '=='  => num_eq       => 260,   0 ],      # foo == bar
    [ '!='  => num_ne       => 260,   0 ],      # foo != bar
    [ '<'   => num_lt       => 260,   0 ],      # foo < bar
    [ '>'   => num_gt       => 260,   0 ],      # foo > bar
    [ '<='  => num_le       => 260,   0 ],      # foo <= bar
    [ '>='  => num_ge       => 260,   0 ],      # foo >= bar
    [ '<=>' => num_cmp      => 260,   0 ],      # foo <=> bar

    # Text comparison operators.  We use the same operator tokens as Perl 
    # does, but give them different token names to disambiguate them from 
    # the numerical comparison operators.
    [ 'eq'  => str_eq       => 260,   0 ],      # foo == bar
    [ 'ne'  => str_ne       => 260,   0 ],      # foo != bar
    [ 'lt'  => str_lt       => 260,   0 ],      # foo < bar
    [ 'gt'  => str_gt       => 260,   0 ],      # foo > bar
    [ 'le'  => str_le       => 260,   0 ],      # foo <= bar
    [ 'ge'  => str_ge       => 260,   0 ],      # foo >= bar
    [ 'cmp' => str_cmp      => 260,   0 ],      # foo <=> bar

    # boolean logic operators
    [ '!'   => 'not'        =>   0, 285 ],      # !foo
    [ '&&'  => 'and_hi'     => 255,   0 ],      # foo && bar
    [ '||'  => 'or_hi'      => 250,   0 ],      # foo || bar
    [ '!!'  => 'nor_hi'     => 250,   0 ],      # foo !! bar

    [ '..'  => range        => 240,   0 ],      # 1 .. 91
    [ 'to'  => to           => 240,   0 ],      # 1 to 91 by 10      # TODO: by
    [ 'by'  => by           => 240,   0 ],      # 1 to 91 by 10      # TODO: by
    
    [ ['->', '→']
            => arrow        => 230,   0 ],      # a -> a + 1

    [ '?'   => if_then      => 225,   0 ],      # foo ? bar : baz
    [ ':'   => if_else      => 225,   0 ],      # foo ? bar : baz       # TODO: terminator

    # binary assignment operators
    [ '='   => assign       => 220,   0 ],      # foo = bar
    [ '=>'  => arrow_fat    => 220,   0 ],         # foo => bar
    [ '~='  => append_to    => 220,   0 ],         # foo ~= bar
    [ '+='  => inc_to       => 220,   0 ],         # foo += bar
    [ '-='  => dec_to       => 220,   0 ],         # foo -= bar
    [ '*='  => mul_to       => 220,   0 ],         # foo *= bar
    [ '/='  => div_to       => 220,   0 ],         # foo /= bar
    [ '&&=' => and_to       => 220,   0 ],         # foo &&= bar
    [ '||=' => or_to        => 220,   0 ],         # foo ||= bar
    [ '!!=' => nor_to       => 220,   0 ],         # foo !!= bar
                                
    # low precedence short-circuiting logical operators
    [ 'not' => 'not'        => 0,   215 ],         # not foo
    [ 'and' => 'and_lo'     => 210,   0 ],         # foo and bar
    [ 'or'  => 'or_lo'      => 205,   0 ],         # foo or bar
    [ 'nor' => 'nor_lo'     => 205,   0 ],         # foo nor bar
                                
    # directive keywords    
    [ 'do'  => 'do'         => 150,   0 ],
    [ 'end'  => 'end'       =>   0,   0 ],
#    [ "${COMMAND}::For"         => 150,   0, 'for', 'in', 'end' ],
#    [ "${COMMAND}::With"        => 150,   0, 'with', 'end' ],
#    [ "${COMMAND}::Block"       =>   0,   0, 'block', 'end' ],
#    [ "${COMMAND}::Dump"        =>   0,   0, 'dump' ],
#    [ "${COMMAND}::Use"         =>   0,   0, 'use' ],
#    [ "${COMMAND}::Tags"        =>   0,   0, 'TAGS' ],
                                
    # constructs
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
