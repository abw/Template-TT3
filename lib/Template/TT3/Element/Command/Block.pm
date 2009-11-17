package Template::TT3::Element::Command::Block;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.  
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token past keyword
    $self->accept($token);

    # parse block following the expression
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

    return $self;
}


sub text {
    $_[SELF]->[RHS]->text( $_[CONTEXT] );
}

1;
