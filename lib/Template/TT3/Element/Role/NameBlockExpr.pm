package Template::TT3::Element::Role::NameBlockExpr;

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

    # parse a block following the expression
    $self->[BLOCK] = $$token
        ->parse_body($token, $scope)
        || return $self->fail_missing( $self->ARG_BLOCK => $token );

    # save the scope in case we need to lookup blocks later
    $self->[ARGS] = $scope;

    return $self;
}

1;

