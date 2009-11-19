package Template::TT3::Element::Command::For;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elements ARRAY',
    constant   => {
        SEXPR_FORMAT => "<for:\n  <expr:\n    %s\n  >\n  <body:\n    %s\n  >\n>",
    },
    alias      => {
        value  => \&text,
    };

sub sexpr {
    my $self   = shift;
    my $format = shift || $self->SEXPR_FORMAT;
    my $expr   = $self->[LHS]->sexpr;
    my $body   = $self->[RHS]->sexpr;
    for ($expr, $body) {
        s/\n/\n    /gsm;
    }
    sprintf(
        $format,
        $expr,
        $body
    );
}
    


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;
    my $lprec = $self->[META]->[LPREC];

    return undef
        if $prec && ! $force && $lprec <= $prec;

    $self->accept($token);
    
    $self->[LHS] = $$token->as_expr($token, $scope, $lprec)
        || return $self->missing( expression => $token );

    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

#    $self->debug("RHS: $self->[RHS]");
#    $self->debug("token: $$token->[TOKEN]");
    # TODO: look for elsif/else
        
    return $self;
}


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    $self->accept($token);

    $self->[RHS] = $lhs;

    $self->[LHS] = $$token->as_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( expression => $token );
    
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub values {
    my ($self, $context) = @_;
    my $value = $self->[LHS]->value($context);
    my @values;
    
    $value = [ $value ] unless ref $value eq ARRAY;
    
#    $self->debug("iterating over $value");

    my $rhs  = $self->[RHS];
    my $vars = $context->{ variables };
    
    foreach my $item (@$value) {
#        $self->debug("setting item to $item");
        $vars->set_var( item => $item );
        push(@values, $rhs->values($context));
    }

    return @values;
}


sub text {
    join('', $_[SELF]->values($_[CONTEXT]));
}


1;
