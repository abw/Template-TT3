package Template::TT3::Element::Command::For;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    constants  => ':elements ARRAY',
    constant   => {
        SEXPR_FORMAT => "<for:\n  <expr:\n    %s\n  >\n  <body:\n    %s\n  >\n>",
        FOLLOW       => {
            map { $_ => 1 }
            qw( elsif else )
        },
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
    


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;
    my $lprec = $self->[META]->[LPREC];

    return undef
        if $prec && ! $force && $lprec <= $prec;

    $self->advance($token);
    
    $self->[LHS] = $$token->parse_expr($token, $scope, $lprec)
        || return $self->missing( expression => $token );

    $self->[RHS] = $$token->parse_body($token, $scope, $self, $self->FOLLOW)
        || return $self->missing( block => $token );

#    $self->debug("RHS: $self->[RHS]");
#    $self->debug("token: $$token->[TOKEN]");
    # TODO: look for elsif/else
        
    return $self;
}


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    $self->advance($token);

    $self->[RHS] = $lhs;

    $self->[LHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( expression => $token );
    
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub else_block {
    return @_ == 1
        ? $_[SELF]->[ELSE]
        : $_[SELF]->[ELSE] = $_[1];
}        


sub values {
    my ($self, $context) = @_;
    my $value = $self->[LHS]->value($context);
    my @values;

    # value must be defined (or should we short-circuit?
    return $self->[LHS]->error_undef_in($self->[TOKEN])
        unless defined $value;
    
    $value = [ $value ] 
        unless ref $value eq ARRAY;
    
    return $self->else_values($context)
        unless @$value;
    
#    $self->debug("iterating over $value");

    my $rhs  = $self->[RHS];
    
    foreach my $item (@$value) {
#        $self->debug("setting item to $item");
        $context->set_var( item => $item );
        push(@values, $rhs->values($context));
    }

    return @values;
}


sub text {
    # Hmmm... should we re-implement this in full so we can call else_text()
    # instead of else_values()?
    join('', $_[SELF]->values($_[CONTEXT]));
}


sub else_values {
    return $_[SELF]->[ELSE]
         ? $_[SELF]->[ELSE]->values($_[CONTEXT])
         : ()
}


sub else_text {
    return $_[SELF]->[ELSE]
         ? $_[SELF]->[ELSE]->text($_[CONTEXT])
         : ()
}



1;
