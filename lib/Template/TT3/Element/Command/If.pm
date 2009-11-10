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

    $self->accept($token);
    
    # skip past keyword and parse expression following
    $self->[LHS] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );

    # parse block following the expression
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

    # TODO: look for elsif/else
        
    return $self;
}


sub text {
    # TODO: should we have a true()/truth() method in elements?
    return $_[SELF]->[RHS]->text($_[CONTEXT])
        if $_[SELF]->[LHS]->value($_[CONTEXT]);
}


1;
