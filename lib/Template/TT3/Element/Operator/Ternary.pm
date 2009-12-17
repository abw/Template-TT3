package Template::TT3::Element::Operator::Ternary;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::Binary
                  Template::TT3::Element',
    view      => 'ternary',
    constants => ':elements',
    constant   => {
        COLON        => ':',
    };


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;
    my $colon;      # snicker

    # Operator precedence
    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    $self->[LHS] = $lhs;
    
    $$token = $self->[NEXT];
    
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( expression => $token );

    $$token->skip_ws($token);
    $colon = $$token;
    $colon->is(COLON, $token)
        || return $self->fail_missing("'" . COLON . "'", $token );
    
    $self->[BRANCH] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC])
        || return $colon->fail_missing( expression => $token );
    
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub text {
    $_[SELF]->[LHS]->value($_[CONTEXT])
        ? $_[SELF]->[RHS]->text($_[CONTEXT])
        : $_[SELF]->[BRANCH]->text($_[CONTEXT])
}

sub value {
    $_[SELF]->[LHS]->value($_[CONTEXT])
        ? $_[SELF]->[RHS]->value($_[CONTEXT])
        : $_[SELF]->[BRANCH]->value($_[CONTEXT])
}


sub values {
    $_[SELF]->[LHS]->value($_[CONTEXT])
        ? $_[SELF]->[RHS]->values($_[CONTEXT])
        : $_[SELF]->[BRANCH]->values($_[CONTEXT])
}

sub pairs {
    $_[SELF]->[LHS]->value($_[CONTEXT])
        ? $_[SELF]->[RHS]->pairs($_[CONTEXT])
        : $_[SELF]->[BRANCH]->pairs($_[CONTEXT])
}




sub left_edge {
    $_[SELF]->[LHS]->left_edge;
}


sub right_edge {
    $_[SELF]->[BRANCH]->right_edge;
}



1;
