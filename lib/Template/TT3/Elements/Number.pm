package Template::TT3::Element::Number;

use Template::TT3::Elements::Literal;
use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    import    => 'class',
    constants => ':elem_slots',
    constant  => {
        SEXPR_FORMAT => '<number:%s>', 
    },
    alias     => {
        as_number => 'self',
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
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TEXT],
    );
}


sub source {
    $_[0]->[TEXT];
}


sub generate {
    $_[1]->generate_number(
        $_[0]->[TEXT]
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
# directly (e.g. $_[0]) wherever possible.  
#-----------------------------------------------------------------------

class->generate_number_ops(
    pre_inc => prefix => sub {                              # ++a 
        return $_[0]->[RHS]->assign(
            $_[1], 
            $_[0]->[RHS]->number($_[1]) + 1
        );
    },
    post_inc => postfix => sub {                            # a++
        my $n = $_[0]->[LHS]->number($_[1]);
        $_[0]->[LHS]->assign(
            $_[1], 
            $n + 1
        );
        return $n;
    },
    pre_dec => prefix => sub {                              # --a
        return $_[0]->[RHS]->assign(
            $_[1], 
            $_[0]->[RHS]->number($_[1]) - 1
        );
    },
    post_dec => postfix => sub {                            # a--
        my $n = $_[0]->[LHS]->number($_[1]);
        $_[0]->[LHS]->assign(
            $_[1], 
            $n - 1
        );
        return $n;
    },
    positive => prefix => sub {                             # +a
        return 
             + $_[0]->[RHS]->number($_[1]);
    },
    negative => prefix => sub {                             # -a
        return
             - $_[0]->[RHS]->number($_[1]);  
    },
    power => infix_right => sub {                           # a ** b
        return $_[0]->[LHS]->number($_[1])
            ** $_[0]->[RHS]->number($_[1]);
    },
    multiply => infix_left => sub {                         # a * b
        return $_[0]->[LHS]->number($_[1])
             * $_[0]->[RHS]->number($_[1]);
    },
    divide => infix_left => sub {                           # a / b
        return $_[0]->[LHS]->number($_[1])
             / $_[0]->[RHS]->number($_[1]);
    },
    div_int => infix_left => sub {                          # a div b
        return int(
               $_[0]->[LHS]->number($_[1])
             / $_[0]->[RHS]->number($_[1])
        );
    },
    modulus => infix_left => sub {                          # a % b
        return $_[0]->[LHS]->number($_[1])                  # a mod b
             % $_[0]->[RHS]->number($_[1])
    },
    add => infix_left => sub {                              # a + b
        return 
            $_[0]->[LHS]->number($_[1])
          + $_[0]->[RHS]->number($_[1]);
    },
    subtract => infix_left => sub {                         # a - b
        return 
            $_[0]->[LHS]->number($_[1])
          - $_[0]->[RHS]->number($_[1]);
    },
    # TODO: comparison operators should all be non-chaining infix
    equal => infix_left => sub {                            # a == b 
        return $_[0]->[LHS]->number($_[1])
            == $_[0]->[RHS]->number($_[1]);
    },
    not_equal => infix_left => sub {                        # a != b
        return $_[0]->[LHS]->number($_[1])
            != $_[0]->[RHS]->number($_[1]);
    },
    less_than => infix_left => sub {                        # a < b
        return $_[0]->[LHS]->number($_[1])
             < $_[0]->[RHS]->number($_[1]);
    },
    more_than => infix_left => sub {                        # a > b
        return $_[0]->[LHS]->number($_[1])
             > $_[0]->[RHS]->number($_[1]);
    },
    less_equal => infix_left => sub {                       # a <= b
        return $_[0]->[LHS]->number($_[1])
            <= $_[0]->[RHS]->number($_[1]);
    },
    more_equal => infix_left => sub {                       # a >= b
        return $_[0]->[LHS]->number($_[1])
            >= $_[0]->[RHS]->number($_[1]);
    },
    compare => infix_left => sub {                          # a <=> b
        return $_[0]->[LHS]->number($_[1])
           <=> $_[0]->[RHS]->number($_[1]);
    },
    add_set => infix => sub {                               # a += b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->number($_[1])
          + $_[0]->[RHS]->number($_[1])
        );
    },
    sub_set => infix => sub {                               # a -= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->number($_[1])
          - $_[0]->[RHS]->number($_[1])
        );
    },
    mul_set => infix => sub {                               # a *= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->number($_[1])
          * $_[0]->[RHS]->number($_[1])
        );
    },
    div_set => infix => sub {                               # a /= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->number($_[1])
          / $_[0]->[RHS]->number($_[1])
        );
    },
);


#-----------------------------------------------------------------------
# Special cases for +/- which are both unary prefix and binary infix 
# operators.  If the operator is at the start of an expression (i.e. 
# as_expr() is called on it) then it upgrades itself to a num_positive
# or num_negative op and delegates to the new as_expr() method.  The 
# num_positive op is Template::TT3::Element::Number::Positive, define as 
# 'positive' in the above call to generate_number_ops().  Ditto for 
# num_negative.  If the operator appears on the right of an expression
# (i.e. as_postop() is called) then it does a similar upgrade and 
# delegates to num_add / num_subtract.
#-----------------------------------------------------------------------

package Template::TT3::Element::Number::Plus;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr   { shift->become('num_positive')->as_expr(@_) }
sub as_postop { shift->become('num_add')->as_postop(@_)    }


package Template::TT3::Element::Number::Minus;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr   { shift->become('num_negative')->as_expr(@_)   }
sub as_postop { shift->become('num_subtract')->as_postop(@_) }


#-----------------------------------------------------------------------
# special cases for *, / and % which can be used in places other than as
# binary operators.
#-----------------------------------------------------------------------

package Template::TT3::Element::Star;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr   { shift->todo }
sub as_postop { shift->become('num_multiply')->as_postop(@_) }


package Template::TT3::Element::Slash;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr   { shift->todo }
sub as_postop { shift->become('num_divide')->as_postop(@_) }


package Template::TT3::Element::Percent;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr   { shift->todo }
sub as_postop { shift->become('num_modulus')->as_postop(@_) }


1;

__END__

