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


class->op_subclass(
    # pre and post auto-increment: ++a a++
    _PreInc => {
        op_base => '_Prefix',
        value   => sub {
            my ($self, $context) = @_;
            $self->[EXPR]->assign(
                $context, 
                $self->[EXPR]->value($context) + 1
            );
        },
    },
    _PostInc => {
        op_base => '_Postfix',
        value   => sub {
            my ($self, $context) = @_;
            my $value = $self->[EXPR]->value($context);
            $self->[EXPR]->assign(
                $context, 
                $value + 1
            );
            return $value;
        },
    },
    _PreDec => {
        op_base => '_Prefix',
        value   => sub {
            my ($self, $context) = @_;
            $self->[EXPR]->assign(
                $context, 
                $self->[EXPR]->value($context) - 1
            );
        },
    },
    _PostDec => {
        op_base => '_Postfix',
        value   => sub {
            my ($self, $context) = @_;
            my $value = $self->[EXPR]->value($context);
            $self->[EXPR]->assign(
                $context, 
                $value - 1
            );
            return $value;
        },
    },


    # unary operators: + -
    _Positive => {
        op_base => '_Prefix',
        value   => sub {
            my ($self, $context) = @_;
            $self->[EXPR]->value($context);  # TODO: assert number
        },
    },
    _Negative => {
        op_base => '_Prefix',
        value   => sub {
            my ($self, $context) = @_;
            - $self->[EXPR]->value($context);  # TODO: assert number
        },
    },

    # binary operators: ** * / % + -
    _Power => {
        op_base => '_InfixRight',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                ** $_[0]->[RHS]->value($_[1]);
        },
    },
    _Multiply => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                 * $_[0]->[RHS]->value($_[1]);
        },
    },
    _Divide => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                 / $_[0]->[RHS]->value($_[1]);
        },
    },
    _DivInt => {
        op_base => '_InfixLeft',
        value   => sub {
            return int( 
                   $_[0]->[LHS]->value($_[1])
                 / $_[0]->[RHS]->value($_[1])
            );
        },
    },
    _Modulus => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                 % $_[0]->[RHS]->value($_[1])
        },
    },
    _Add => {
        op_base => '_InfixLeft',
        value   => sub {
            my ($self, $context) = @_;
            return 
                $self->[LHS]->value($context)
              + $self->[RHS]->value($context);
        },
    },
    _Subtract => {
        op_base => '_InfixLeft',
        value   => sub {
            my ($self, $context) = @_;
            return 
                $self->[LHS]->value($context)
              - $self->[RHS]->value($context);
        },
    },

    # comparison operators
    # TODO: these should all be non-chaining infix
    _Equal => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                == $_[0]->[RHS]->value($_[1]);
        },
    },
    _NotEqual => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                != $_[0]->[RHS]->value($_[1]);
        },
    },
    _LessThan => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                 < $_[0]->[RHS]->value($_[1]);
        },
    },
    _MoreThan => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                 > $_[0]->[RHS]->value($_[1]);
        },
    },
    _LessEqual => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                <= $_[0]->[RHS]->value($_[1]);
        },
    },
    _MoreEqual => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
                >= $_[0]->[RHS]->value($_[1]);
        },
    },
    _Compare => {
        op_base => '_InfixLeft',
        value   => sub {
            return $_[0]->[LHS]->value($_[1])
               <=> $_[0]->[RHS]->value($_[1]);
        },
    }
);


#-----------------------------------------------------------------------
# special cases for +/- which can masquerade as both unary prefix 
# and binary infix operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Number::Plus;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr {
    shift->become('num_positive')->as_expr(@_);
}

sub as_postop {
    shift->become('num_add')->as_postop(@_);
}


package Template::TT3::Element::Number::Minus;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr {
    shift->become('num_negative')->as_expr(@_);
}

sub as_postop {
    shift->become('num_subtract')->as_postop(@_);
}


#-----------------------------------------------------------------------
# special cases for * and / which can be used in places other than as
# binary operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Star;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    methods   => {
        as_expr => sub {
            shift->not_implemented;
        },
        as_postop => sub {
            shift->become('num_multiply')->as_postop(@_);
        },
    };


package Template::TT3::Element::Slash;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    methods   => {
        as_expr => sub {
            shift->not_implemented;
        },
        as_postop => sub {
            shift->become('num_divide')->as_postop(@_);
        },
    };


package Template::TT3::Element::Percent;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    methods   => {
        as_expr => sub {
            shift->not_implemented;
        },
        as_postop => sub {
            shift->become('num_divide')->as_postop(@_);
        }
    };



1;

__END__

    'PostInc' => {
        base      => 'Template::TT3::Element::Postfix',
        methods   => {
            value => sub {
                my ($self, $context) = @_;
                my $value = $self->[EXPR]->value($context);
                $self->[EXPR]->assign(
                    $context, 
                    $value + 1
                );
                return $value;
            },
        },
    },

    # pre and post auto-decrement: --a a--
    'Template::TT3::Element::Number::PreDec' => {
        base      => 'Template::TT3::Element::Prefix',
        constants => 'EXPR',
        methods   => {
            value => sub {
                my ($self, $context) = @_;
                $self->[EXPR]->assign(
                    $context, 
                    $self->[EXPR]->value($context) - 1
                );
            },
        },
    },
    'Template::TT3::Element::Number::PostDec' => {
        constants => 'EXPR',
        base      => 'Template::TT3::Element::Postfix',
        methods   => {
            value => sub {
                my ($self, $context) = @_;
                my $value = $self->[EXPR]->value($context);
                $self->[EXPR]->assign(
                    $context, 
                    $value - 1
                );
                return $value;
            },
        },
    },

1;
