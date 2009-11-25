package Template::TT3::Element::Role::ArgsBlockExpr;

use Template::TT3::Class 
    version   => 2.718,
    debug     => 0,
    mixins    => 'parse_expr',
    constants => ':elements :precedence';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance past keyword
    $$token = $self->[NEXT];

    # parse list of parameters
    $self->[ARGS] = $$token->parse_pairs($token, $scope, undef, 1);
        
    # parse a block following the args
    $self->[BLOCK] = $$token
        ->parse_body($token, $scope)
        || return $self->missing_error( $self->ARG_BLOCK => $token );

    return $self;
}


1;