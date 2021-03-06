package Template::TT3::Element::Command::If;

use Template::TT3::Class::Element
    version    => 2.68,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'if',
    follow     => 'elsif else',
    source     => '%s %s { %s }',
    alias      => {
        value  => \&text,
    };


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
        ? $_[SELF]->[BRANCH]
        : $_[SELF]->[BRANCH] = $_[1];
}        


sub true {
    return $_[SELF]->[LHS]->value($_[CONTEXT]);
}


sub text {
    return $_[SELF]->true($_[CONTEXT])
         ? $_[SELF]->[RHS]->text($_[CONTEXT])
         : $_[SELF]->[BRANCH]
            ? $_[SELF]->[BRANCH]->text($_[CONTEXT])
            : ();
}


sub values {
    return $_[SELF]->true($_[CONTEXT])
         ? $_[SELF]->[RHS]->values($_[CONTEXT])
         : $_[SELF]->[BRANCH]
            ? $_[SELF]->[BRANCH]->values($_[CONTEXT])
            : ();
}


sub pairs {
    return $_[SELF]->true($_[CONTEXT])
         ? $_[SELF]->[RHS]->pairs($_[CONTEXT])
         : $_[SELF]->[BRANCH]
            ? $_[SELF]->[BRANCH]->pairs($_[CONTEXT])
            : ();
}


sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT,
        $self->[TOKEN],
        $self->[LHS]->source,
        $self->[RHS]->source,
    );
}


1;
