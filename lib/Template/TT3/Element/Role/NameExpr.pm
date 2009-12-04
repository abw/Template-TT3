package Template::TT3::Element::Role::NameExpr;

use Template::TT3::Class 
    version   => 2.718,
    mixins    => 'parse_expr',
    constants => ':elements';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance past the keyword and whitespace then parse a filename
    $self->[EXPR] = $$token
        ->next_skip_ws($token)
        ->parse_filename($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( $self->ARG_NAME => $token );

    # save the scope so we can lookup lexically scoped blocks later
    $self->[ARGS] = $scope;

    # parse infix operators
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}

1;

