package Template::TT3::Element::Command::As;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Keyword',
    constants  => ':elements',
    as         => 'expr_block_expr',
    alias      => {
#        value  => \&text,
        values => \&value,
    };


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS and advance token past keyword (yes, that's right, we 
    # store the LHS argument as our RHS, because we usually expect the 
    # variable name to be on the LHS, e.g. C<as varname { ... }>
    $self->[BLOCK] = $lhs;
    $self->accept($token);

    # parse variable name expression
    $self->[EXPR] = $$token->as_expr($token, $scope)
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
        ->set( $_[SELF]->[BLOCK]->text( $_[CONTEXT] ) );
}



1;
