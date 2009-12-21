package Template::TT3::Element::Operator::Prefix;

use Template::TT3::Class
    version   => 2.68,
    base      => 'Template::TT3::Element::Operator::Unary',
    view      => 'prefix',
    constants => ':elements',
    constant  => {
        DEBUG_FORMAT => 'prefix: [<1>] [<4> => <5>]',
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;

    # operator precedence
    return undef 
        if $prec && $self->[META]->[RPREC] < $prec;

    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[RPREC])
        || $self->fail_missing( expression => $token );

    # carry on...
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[TOKEN],
        $_[0]->[RHS]->source
    );
}

1;
