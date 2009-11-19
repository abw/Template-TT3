package Template::TT3::Element::Role::NullExpr;

use Template::TT3::Class 
    version   => 2.718,
    mixins    => 'as_expr',
    constants => ':elements';


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # accept the current token and advance to the next one
    $$token = $self->[NEXT];

    return $self;
}

1;