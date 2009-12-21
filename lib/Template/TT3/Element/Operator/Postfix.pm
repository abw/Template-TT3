package Template::TT3::Element::Operator::Postfix;

use Template::TT3::Class
    version   => 2.68,
    base      => 'Template::TT3::Element::Operator::Unary',
    view      => 'postfix',
    constants => ':elements',
    constant  => {
        DEBUG_FORMAT => 'postfix: [<2> => <3>] [<1>]',
    };


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return undef 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # stash away the expression on our left
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # carry on...
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[LHS]->source,
        $_[0]->[TOKEN],
    );
}

1;