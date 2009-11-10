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
    my ($self, $token, $scope, $prec) = @_;

    # operator precedence
    return undef
        if $prec && $self->[META]->[LPREC] <= $prec;

    # parse expression
    $self->[LHS] = $$token->next->as_expr($token, $scope)
        || return $self->missing( expression => $token );

    # parse block
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );
        
    return $self;
}

sub text {
    # hmmm... we need a way to only return value from last expr
#    $_[SELF]->debug("if $_[SELF]->[RHS] / $_[SELF]->[RHS]");
    return $_[SELF]->[RHS]->text($_[CONTEXT])
        if $_[SELF]->[LHS]->value($_[CONTEXT]);
}


1;
