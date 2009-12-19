package Template::TT3::Element::Role::Expr::Name;

use Template::TT3::Class 
    version   => 2.718,
    mixins    => 'parse_expr',
    constants => ':elements';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # Advance past the keyword and whitespace, then parse a filename
    $self->[EXPR] = $$token
        ->next_skip_ws($token)
        ->parse_filename($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( $self->ARG_NAME => $token );

    # Save the scope so we can lookup lexically scoped blocks later
    # NOTE: there is no guarantee this this method won't get mixed into 
    # a module which does something else with the ARGS slot.
    $self->[ARGS] = $scope;

    # Parse any infix operators following this expression
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


1;

