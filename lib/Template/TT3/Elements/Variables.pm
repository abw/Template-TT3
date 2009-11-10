#-----------------------------------------------------------------------
# Template::TT3::Element::Word - literal word elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Word;

use Template::TT3::Elements::Literal;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots';


sub generate {
    $_[1]->generate_word(
        $_[0]->[TOKEN],
    );
}


sub as_expr {
    shift->become('variable')->as_expr(@_);
}


sub as_dotop {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    $self->debug("using $self->[TOKEN] as dotop: $self\n") if DEBUG;
    return $self;
}

sub value {
    $_[0]->[TOKEN];
}


package Template::TT3::Element::Variable;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots :eval_args',
    constant  => {
        SEXPR_FORMAT => '<variable:%s>', 
    },
    alias => {
        source => 'token',
    };


sub as_expr {
    my ($self, $token, $scope, $prec) = @_;
    
    # ask scope to lookup variable from the symbol table

    # TODO: allow () [] {} following variable word
    
    # advance token
    $$token = $self->[NEXT];
    
    # variables can be followed by postops (postfix and infix operators)
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}

sub generate {
    $_[1]->generate_variable(
        $_[0]->[TOKEN],
    );
}

sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TOKEN],
    );
}

sub value {
#    return $_[1]->{ variables }
#         ->value( $_[0]->[TOKEN] );

    # this seems rather redundant... why not just request the value?
    # Why?  Because it misses the variable cache
    $_[1]->{ variables }
         ->var( $_[0]->[TOKEN] )
         ->value( $_[1] );
}

sub values {
    # as above, we should shortcut
    $_[1]->{ variables }
         ->var( $_[0]->[TOKEN] )
         ->values( $_[1] );
}

sub variable {
    $_[1]->{ variables }
         ->var( $_[0]->[TOKEN] );
}

sub assign {
    $_[SELF]->variable($_[CONTEXT])->set($_[2]);
#    return ();
}


#-----------------------------------------------------------------------
# dotop
#-----------------------------------------------------------------------

package Template::TT3::Element::Dot;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::Binary
                  Template::TT3::Element',
    constants => ':elem_slots';


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # Operator precedence - if our leftward binding precedence is less than
    # or equal to the precedence requested then we return the LHS.  
    # The 'or equal' part gives us left asociativity so that "a + b + c"
    # is parsed as "(a + b) + c"
    return $lhs 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # otherwise this operator has a higher precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter
    $self->[RHS] = $$token->as_dotop($token, $scope, $self->[META]->[LPREC])
        || return $self->error("Missing expression after dotop");

    $self->debug("DOT as_postop() [$self->[LHS]] [$self->[RHS]]") if DEBUG;
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub value {
    my ($self, $context) = @_;
    my $lhs = $self->[LHS]->variable($context);
    my $rhs = $self->[RHS]->value($context);
    $self->debug("DOT value() [$self->[LHS] => $lhs] [$self->[RHS] => $rhs]\n") if DEBUG;
    $lhs->dot($rhs)->value($context);
}


sub variable {
    # args are ($self, $context)
    # $self->[LHS]->variable($context)->dot($rhs->value($context));
    $_[0]->[LHS]->variable($_[1])->dot(
        $_[0]->[RHS]->value($_[1])
    );
}




1;
