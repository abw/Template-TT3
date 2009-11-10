package Template::TT3::Element::Command::If;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token
    $self->accept($token);
    
    # parse expression following
    $self->[LHS] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );

    # parse block following the expression
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

    # TODO: look for elsif/else
        
    return $self;
}


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS and advance token past keyword
    $self->[RHS] = $lhs;
    $self->accept($token);

    # parse expression
    $self->[LHS] = $$token->as_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( expression => $token );
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
#    return $self;
}


sub text {
    # TODO: should we have a true()/truth() method in elements?
    return $_[SELF]->[LHS]->value($_[CONTEXT])
        ? $_[SELF]->[RHS]->text($_[CONTEXT])
        : ();
}


1;
