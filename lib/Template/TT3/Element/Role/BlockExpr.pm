package Template::TT3::Element::Role::BlockExpr;

use Template::TT3::Class 
    version   => 2.718,
    mixins    => 'parse_expr',
    constants => ':elements';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # skip over the keywords and any trailing whitespace, then parse the 
    # following block
    $self->[BLOCK] = $$token
        ->next_skip_ws($token)
        ->parse_body($token, $scope)
        || return $self->missing( $self->ARG_BLOCK => $token );
        
    return $self;
}

1;

