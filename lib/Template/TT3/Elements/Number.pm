package Template::TT3::Element::Number;

use Template::TT3::Elements::Literal;
use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    import    => 'class',
    constants => ':elem_slots :eval_args',
    constant  => {
        SEXPR_FORMAT => '<number:%s>', 
    },
    alias     => {
        as_number => 'self',        # this is already a number op
        as_dotop  => 'accept',
        number    => 'value',       # our token contains the number
    };


sub as_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance token
    $$token = $self->[NEXT];
    
    # variables can be followed by postops (postfix and infix operators)
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub sexpr {
    sprintf(
        $_[SELF]->SEXPR_FORMAT, 
        $_[SELF]->[TOKEN],
    );
}


sub source {
    $_[SELF]->[TOKEN];
}


sub generate {
    $_[CONTEXT]->generate_number(
        $_[SELF]->[TOKEN]
    );
}



#-----------------------------------------------------------------------
# Call on generate_number_ops() (in Template::TT3::Class) to create a 
# bunch of subclasses of Template::TT3::Element::Number.  The first
# argument is a class name (e.g. pre_inc) which gets CamelCased and 
# added to the base (e.g. Template::TT3::Element::Number::PreInc). Any
# subsequent names are operator base classes.  These are also CamelCased 
# and added to the operator base class name (e.g. 'infix_right' becomes 
# Template::TT3::Element::Operator::InfixRight).  Then we have a code 
# reference which implements the value() method for the operator.  For 
# number operators this is also aliased as values(), number() and text().
# All operands to numerical operators (e.g. EXPR, LHS and RHS) must 
# yield numerical values, so we call number() rather than value().  If
# they are already numerical expressions then we'll get the shortcut to
# the value() method.  Otherwise the operand's number() method will do
# the right thing to assert that the value it yields is numeric.
# For the sake of runtime efficiency, we try to access stack arguments
# directly (e.g. $_[SELF]) wherever possible.  
#-----------------------------------------------------------------------

BEGIN {
class->generate_number_ops(
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
        return 
            $_[SELF]->[LHS]->number($_[CONTEXT])
          + $_[SELF]->[RHS]->number($_[CONTEXT]);
    },
    subtract => infix_left => sub {                         # a - b
        return 
            $_[SELF]->[LHS]->number($_[CONTEXT])
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
    
    # TODO: these should be $lhs->variable->set(...)
);

#-----------------------------------------------------------------------
# A call to generate_number_assign_ops() which performs much the same 
# task as generate_number_ops() but inherits the text() method from the 
# T::TT3::Element::Operator::Assignment base class instead of aliasing 
# it to the value() method.
#-----------------------------------------------------------------------

class->generate_number_assign_ops(
    pre_inc => prefix => assignment => sub {                # ++a 
        return $_[SELF]->[RHS]->assign(
            $_[CONTEXT], 
            $_[SELF]->[RHS]->number($_[CONTEXT]) + 1
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
    pre_dec => prefix => assignment => sub {                # --a
        return $_[SELF]->[RHS]->assign(
            $_[CONTEXT], 
            $_[SELF]->[RHS]->number($_[CONTEXT]) - 1
        )->value;
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
        return $_[SELF]->[LHS]->assign(
            $_[CONTEXT], 
            $_[SELF]->[LHS]->number($_[CONTEXT])
          + $_[SELF]->[RHS]->number($_[CONTEXT])
        )->value;
    },
    sub_set => infix_right => assignment => sub {           # a -= b
        return $_[SELF]->[LHS]->assign(
            $_[CONTEXT], 
            $_[SELF]->[LHS]->number($_[CONTEXT])
          - $_[SELF]->[RHS]->number($_[CONTEXT])
        )->value;
    },
    mul_set => infix_right => assignment => sub {           # a *= b
        return $_[SELF]->[LHS]->assign(
            $_[CONTEXT], 
            $_[SELF]->[LHS]->number($_[CONTEXT])
          * $_[SELF]->[RHS]->number($_[CONTEXT])
        )->value;
    },
    div_set => infix_right => assignment => sub {           # a /= b
        return $_[SELF]->[LHS]->assign(
            $_[CONTEXT], 
            $_[SELF]->[LHS]->number($_[CONTEXT])
          / $_[SELF]->[RHS]->number($_[CONTEXT])
        )->value;
    },
);
}


#-----------------------------------------------------------------------
# Another call to generate_pre_post_ops() which defines operator classes
# that can be either prefix operators or postfix operators.  e.g. '-'
# and '+' can be prefix or postfix (infix).
#
# If the operator, say '+', is at the start of an expression (i.e. as_expr() 
# is called on it) then it upgrades itself to a num_positive op and 
# delegates to the new as_expr() method.  The num_positive op is 
# Template::TT3::Element::Number::Positive, define as 'positive' in the 
# earlier call to generate_number_ops().  If the operator appears on the 
# right of an expression (i.e. as_postop() is called) then it does a 
# similar upgrade and delegates to num_add.
#-----------------------------------------------------------------------

class->generate_pre_post_ops(
    inc   => ['num_pre_inc',  'num_post_inc'],
    dec   => ['num_pre_dec',  'num_post_dec'],
    plus  => ['num_positive', 'num_add'],
    minus => ['num_negative', 'num_subtract'],
);



#-----------------------------------------------------------------------
# range
#-----------------------------------------------------------------------

package Template::TT3::Element::Number::Range;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Infix
                  Template::TT3::Element',
    constants => ':eval_args :elem_slots BLANK';

sub text {
    join(BLANK, @{ $_[SELF]->value($_[CONTEXT]) });
}

sub values {
    @{ $_[SELF]->value($_[CONTEXT]) };
}

sub value {
    [ 
        $_[SELF]->[LHS]->number($_[CONTEXT])
     .. $_[SELF]->[RHS]->number($_[CONTEXT])
    ]
}



#-----------------------------------------------------------------------
# '/' can be used as a filename separator: foo/bar.tt3
#-----------------------------------------------------------------------

package Template::TT3::Element::Number::Divide;

use Template::TT3::Class 
    as => 'filename';


#-----------------------------------------------------------------------
# special cases for *, / and % which can be used in places other than as
# binary operators.
#-----------------------------------------------------------------------

package Template::TT3::Element::Number::Multiply;


package Template::TT3::Element::Number::Percent;

use Template::TT3::Class 
    base => 'Template::TT3::Element::Number::Modulus';

package Template::TT3::Element::Number::To;

use Template::TT3::Class 
    base => 'Template::TT3::Element::Number::Range';

1;

__END__

