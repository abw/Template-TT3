package Template::TT3::Element::Command::If;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'if',
    constants  => ':elements',
    constant   => {
        SEXPR_FORMAT => "<if:\n  <expr:\n    %s\n  >\n  <body:\n    %s\n  >\n>",
        FOLLOW       => {
            map { $_ => 1 }
            qw( elsif else )
        },
    },
    alias      => {
        value  => \&text,
#        values => \&text,
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

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token
    $self->advance($token);

    # look for an optional fragment
    $self->[FRAGMENT] = $$token->parse_fragment($token, $scope);
    
    # parse expression following
    $self->[LHS] = $$token->parse_expr($token, $scope, $lprec)
        || return $self->fail_missing( expression => $token );

    # parse block following the expression
    $self->[RHS] = $$token->parse_body($token, $scope, $self, $self->FOLLOW)
        || return $self->fail_missing( block => $token );

    # TODO: look for any following operators
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
        
    return $self;
}


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS and advance token past keyword
    $self->[RHS] = $lhs;
    $self->advance($token);

    # parse expression
    $self->[LHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( expression => $token );
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
#    return $self;
}


sub else_block {
    return @_ == 1
        ? $_[SELF]->[ELSE]
        : $_[SELF]->[ELSE] = $_[1];
}        


sub text {
    # TODO: should we have a true()/truth() method in elements?
    return $_[SELF]->[LHS]->value($_[CONTEXT])
         ? $_[SELF]->[RHS]->text($_[CONTEXT])
         : $_[SELF]->[ELSE]
            ? $_[SELF]->[ELSE]->text($_[CONTEXT])
            : ();
}

sub values {
    return $_[SELF]->[LHS]->value($_[CONTEXT])
         ? $_[SELF]->[RHS]->values($_[CONTEXT])
         : $_[SELF]->[ELSE]
            ? $_[SELF]->[ELSE]->values($_[CONTEXT])
            : ();
}


sub pairs {
    return $_[SELF]->[LHS]->value($_[CONTEXT])
         ? $_[SELF]->[RHS]->pairs($_[CONTEXT])
         : $_[SELF]->[ELSE]
            ? $_[SELF]->[ELSE]->pairs($_[CONTEXT])
            : ();
}


sub source {
    my $self = shift;
    my $expr = $self->[LHS]->source;
    my $body = $self->[RHS]->source;
    return "if $expr { $body }";
}

1;
