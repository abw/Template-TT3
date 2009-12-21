package Template::TT3::Element::Operator::InfixLeft;

use Template::TT3::Class
    version   => 2.68,
    base      => 'Template::TT3::Element::Operator::Binary',
    constants => ':elements';


sub parse_infix {
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
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
        || return $self->fail_missing( expression => $token );
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}

1;

