package Template::TT3::Element::Role::ArgsExpr;

use Template::TT3::Class 
    version   => 2.718,
    mixins    => 'parse_expr',
    constants => ':elements';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance past the keyword and whitespace then parse a list of 
    # expressions of any precedence (0), allowing none (1)
    $self->[ARGS] = $$token
        ->next_skip_ws($token)
        ->parse_block($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );

    return $self;
}


1;

