package Template::TT3::Element::Command::As;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    alias      => {
#        value  => \&text,
        values => \&value,
    };


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.  If the $force flag is set (indicating that we're
    # on the RHS of an assignment operator which really, REALLY wants an 
    # expression) then we continue even if our precedence is lower than that
    # specified
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token past keyword
    $self->accept($token);

    # parse variable name expression
    $self->[LHS] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );

    # parse block following the expression
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

    return $self;
}


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS and advance token past keyword (yes, that's right, we 
    # store the LHS argument as our RHS, because we usually expect the 
    # variable name to be on the LHS, e.g. C<as varname { ... }>
    $self->[RHS] = $lhs;
    $self->accept($token);

    # parse variable name expression
    $self->[LHS] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );
    
    return $self;
}


sub text {
    $_[SELF]->variable($_[CONTEXT])->BLANK;
}

sub value {
    $_[SELF]->variable($_[CONTEXT])->value;
}

sub variable {
    $_[SELF]->[LHS]
        ->variable( $_[CONTEXT] )
        ->set( $_[SELF]->[RHS]->text( $_[CONTEXT] ) );
}



1;
