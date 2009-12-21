package Template::TT3::Element::Operator::Binary;

use Template::TT3::Class
    version   => 2.69,
    base      => 'Template::TT3::Element::Operator',
    view      => 'binary',
    constants => ':elements',
    constant  => {
        SOURCE_FORMAT => '%s %s %s', 
        DEBUG_FORMAT  => 'infix: [<1>] [<2> => <3>] [<4> => <5>]',
    };


sub parse_expr {
    my ($self, $token, $scope) = @_;
    return undef;
}


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[LHS]->source,
        $_[0]->[TOKEN], 
        $_[0]->[RHS]->source,
    );
}


sub left_edge {
    $_[0]->[LHS]->left_edge;
}


sub right_edge {
    $_[0]->[RHS]->right_edge;
}

1;
