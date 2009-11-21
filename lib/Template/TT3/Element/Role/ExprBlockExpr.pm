package Template::TT3::Element::Role::ExprBlockExpr;

use Template::TT3::Class 
    version   => 2.718,
    mixins    => 'parse_expr',
    constants => ':elements';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance past the keyword and whitespace then parse an expression
    $self->[EXPR] = $$token->next_skip_ws($token)
        ->parse_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( $self->ARG_EXPR => $token );

    # parse block following the expression
    $self->[BLOCK] = $$token->parse_body($token, $scope)
        || return $self->missing( $self->ARG_BLOCK => $token );

    return $self;
}


1;