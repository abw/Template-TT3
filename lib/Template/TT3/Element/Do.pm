package Template::TT3::Element::Do;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots';

sub generate {
    my $self = $_[0];
#    $self->debug("EXPRS: $self->[EXPR]");
    $_[1]->generate_do(
        $_[0]->[TEXT],
        $_[0]->[EXPR],
    );
}

sub as_expr {
    my ($self, $token, $scope, $prec) = @_;

    # operator precedence
    return undef
        if $prec && $self->[META]->[LPREC] <= $prec;

    # advance token past 'do' keyword
    $$token = $self->[NEXT];
    
    # parse block
    $self->[EXPR] = $$token->as_block($token, $scope)
        || return $self->error("Missing block after $self->[TEXT]");
    
    return $self;
}


1;
