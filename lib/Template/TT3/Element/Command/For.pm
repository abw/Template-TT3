package Template::TT3::Element::Command::For;

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

    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    $self->accept($token);
    
    $self->[LHS] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );

    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

    # TODO: look for elsif/else
        
    return $self;
}


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    $self->accept($token);

    $self->[RHS] = $lhs;

    $self->[LHS] = $$token->as_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( expression => $token );
    
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub text {
    # TODO: should we have a true()/truth() method in elements?
    return $_[SELF]->[LHS]->value($_[CONTEXT])
        ? $_[SELF]->[RHS]->text($_[CONTEXT])
        : ();
}


1;
