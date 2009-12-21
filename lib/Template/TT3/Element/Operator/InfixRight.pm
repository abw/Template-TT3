package Template::TT3::Element::Operator::InfixRight;

use Template::TT3::Class
    version   => 2.68,
    base      => 'Template::TT3::Element::Operator::Binary',
    constants => ':elements';


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # This is identical to parse_infix() in T::E::O::InfixLeft all but one 
    # regard.  If we have an equal precedence between two consecutive 
    # operators then we bind the RHS pair tighter than the LHS pair, e.g.
    # "a = b = c" is parsed as "a = (b = c)".  To implement this we just 
    # need to change <= to < in the comparison.  Equal operators now 
    # continue instead of returning as they do for left associativity.
    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    # otherwise this operator has a >= precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher or equal precedence can bind tighter
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
        || return $self->fail_missing( expression => $token );
    
    # at this point the next token might be a lower or equal precedence 
    # operator, so we give it a chance to continue with the current operator
    # as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}

1;