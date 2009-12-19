package Template::TT3::Element::Operator::Number;

use Template::TT3::Elements::Operator;          # FIXME
use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',      # TODO: +Operator
    import    => 'class',
    constant  => {
        SEXPR_FORMAT => '<number:%s>',          # TODO: remove me
    };


sub variable {
    # variable operations can be converted to a variable in order to 
    # perform dotops on it
    $_[CONTEXT]->use_var( 
        $_[SELF], $_[SELF]->value( $_[CONTEXT] ) 
    );
}

sub sexpr {
    sprintf(
        $_[SELF]->SEXPR_FORMAT, 
        $_[SELF]->[TOKEN],
    );
}



#-----------------------------------------------------------------------
# Use generate_elements() (in Template::TT3::Class::Element) to create
# a bunch of subclasses of Template::TT3::Element::Operator::Number.
#
# The first argument is a class name (e.g. pre_inc) which gets CamelCased 
# and added to the base class package (e.g. 'pre_inc' is mapped to 
# Template::TT3::Element::Operator::Number::PreInc). Any subsequent names 
# are operator base classes.  These are also CamelCased and added to the 
# operator base class name (e.g. 'infix_right' becomes 
# Template::TT3::Element::Operator::InfixRight).  
#
# Then we have a code reference which implements the value() method for 
# the operator.  For numerical operators this is also aliased as values(), 
# number() and text().
#
# All operands to numerical operators (e.g. EXPR, LHS and RHS) must 
# yield numerical values, so we call number() rather than value().  If
# they are already numerical expressions then we'll get the shortcut to
# the value() method.  Otherwise the operand's number() method will do
# the right thing to assert that the value it yields is numeric.
# For the sake of runtime efficiency, we try to access stack arguments
# directly (e.g. $_[SELF]) wherever possible.  
#-----------------------------------------------------------------------

class->generate_elements(
    {
        methods => 'text number value values' 
    },

    positive => prefix => sub {                             # +a
        return 
             + $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    negative => prefix => sub {                             # -a
        return
             - $_[SELF]->[RHS]->number($_[CONTEXT]);  
    },
    power => infix_right => sub {                           # a ** b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
            ** $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    multiply => infix_left => sub {                         # a * b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
             * $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    divide => infix_left => sub {                           # a / b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
             / $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    div_int => infix_left => sub {                          # a div b
        return int(
               $_[SELF]->[LHS]->number($_[CONTEXT])
             / $_[SELF]->[RHS]->number($_[CONTEXT])
        );
    },
    modulus => infix_left => sub {                          # a % b
        return $_[SELF]->[LHS]->number($_[CONTEXT])         # a mod b
             % $_[SELF]->[RHS]->number($_[CONTEXT])
    },
    add => infix_left => sub {                              # a + b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
             + $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    subtract => infix_left => sub {                         # a - b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
             - $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    equal => infix => sub {                                 # a == b 
        return $_[SELF]->[LHS]->number($_[CONTEXT])
            == $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    not_equal => infix => sub {                             # a != b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
            != $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    less_than => infix => sub {                             # a < b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
             < $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    more_than => infix => sub {                             # a > b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
             > $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    less_equal => infix => sub {                            # a <= b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
            <= $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    more_equal => infix => sub {                            # a >= b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
            >= $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    compare => infix => sub {                               # a <=> b
        return $_[SELF]->[LHS]->number($_[CONTEXT])
           <=> $_[SELF]->[RHS]->number($_[CONTEXT]);
    },

);


#-----------------------------------------------------------------------
# Same again, but without aliasing the function to the text() method.  
# Instead we inherit the text() method from the T~Operator::Assignment 
# base class which performs the assignment (by calling $self->value()) 
# but returns an empty list. This is how we silence assignment operators 
# from generating any output in "text context", e.g. [% a = 10 %]
#-----------------------------------------------------------------------

class->generate_elements(
    {   
        methods => 'number value values' 
    },

    pre_inc => prefix => assignment => sub {                # ++a 
        return 
            $_[SELF]->[RHS]->assign(
                $_[CONTEXT], 
                $_[SELF]->[RHS]->number($_[CONTEXT]) + 1
            )->value;
    },
    pre_dec => prefix => assignment => sub {                # --a
        return 
            $_[SELF]->[RHS]->assign(
                $_[CONTEXT], 
                $_[SELF]->[RHS]->number($_[CONTEXT]) - 1
            )->value;
    },
    post_inc => postfix => assignment => sub {              # a++
        my $n = $_[SELF]->[LHS]->number($_[CONTEXT]);
        $_[SELF]->[LHS]->assign(
            $_[CONTEXT], 
            $n + 1
        );
        return $n;
    },
    post_dec => postfix => assignment => sub {              # a--
        my $n = $_[SELF]->[LHS]->number($_[CONTEXT]);
        $_[SELF]->[LHS]->assign(
            $_[CONTEXT], 
            $n - 1
        );
        return $n;
    },
    add_set => infix_right => assignment => sub {           # a += b
        return 
            $_[SELF]->[LHS]->assign(
                $_[CONTEXT], 
                $_[SELF]->[LHS]->number($_[CONTEXT])
              + $_[SELF]->[RHS]->number($_[CONTEXT])
            )->value;
    },
    sub_set => infix_right => assignment => sub {           # a -= b
        return 
            $_[SELF]->[LHS]->assign(
                $_[CONTEXT], 
                $_[SELF]->[LHS]->number($_[CONTEXT])
              - $_[SELF]->[RHS]->number($_[CONTEXT])
            )->value;
    },
    mul_set => infix_right => assignment => sub {           # a *= b
        return 
            $_[SELF]->[LHS]->assign(
                $_[CONTEXT], 
                $_[SELF]->[LHS]->number($_[CONTEXT])
              * $_[SELF]->[RHS]->number($_[CONTEXT])
            )->value;
    },
    div_set => infix_right => assignment => sub {           # a /= b
        return 
            $_[SELF]->[LHS]->assign(
                $_[CONTEXT], 
                $_[SELF]->[LHS]->number($_[CONTEXT])
              / $_[SELF]->[RHS]->number($_[CONTEXT])
            )->value;
    },
);


#-----------------------------------------------------------------------
# A call to generate_pre_post_ops() which defines operator classes
# that can be either prefix operators or postfix operators.  e.g. '-'
# and '+' can be prefix or postfix (infix).
#
# If the operator, say '+', is at the start of an expression (i.e. parse_expr() 
# is called on it) then it upgrades itself to a num_positive op and 
# delegates to the new parse_expr() method.  The num_positive op is 
# Template::TT3::Element::Number::Positive, define as 'positive' in the 
# earlier call to generate_number_ops().  If the operator appears on the 
# right of an expression (i.e. parse_infix() is called) then it does a 
# similar upgrade and delegates to num_add.
#-----------------------------------------------------------------------

class->generate_pre_post_ops(
    inc     => ['num_pre_inc',  'num_post_inc'],
    dec     => ['num_pre_dec',  'num_post_dec'],
    plus    => ['num_positive', 'num_add'],
    minus   => ['num_negative', 'num_subtract'],
);


#-----------------------------------------------------------------------
# Tweak: '/' can be used as a filename separator: foo/bar.tt3
#-----------------------------------------------------------------------

class->subclass('divide')
     ->roles('filename');

1;

__END__

