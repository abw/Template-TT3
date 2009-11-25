package Template::TT3::Element::Command::Dot;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command::Block',
    constants  => ':elements',
    constant   => {
        ARG_NAME      => 'decoder',
        SOURCE_FORMAT => '%s %s %s',
    },
    alias      => {
#        value  => \&text,
#        values => \&value,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # parse next item as dotop   # FIXME: precedence?
    $self->[RHS] = $$token->next_skip_ws($token)->parse_dotop($token, $scope, $self->[META]->[LPREC])
        || return $self->missing_error( dotop => $token );

    # capture any args... 
    $self->[ARGS] = $$token->parse_args($token, $scope);

    # there may be other dotops following
    my $result = $$token->skip_ws->parse_infix($self, $token, $scope, $self->[META]->[LPREC]);
    
    if (DEBUG) {
        $self->debug("expr args: ", $self->[ARGS]);
        $self->debug("next token is ", $$token->next_skip_ws->token);
    }

    # parse block following the expression
    $self->[LHS] = $$token->parse_body($token, $scope)
        || return $self->missing_error( block => $token );

    $self->debug("dot command as expr: $self->[LHS] dot $self->[RHS]") if DEBUG;

    # We return the result of doing any more dotops after this one.  
    # If there are no more dotops then $result will be $self
    return $result;
}


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store LHS
    $self->[LHS] = $lhs;

    my $other = $$token->next_skip_ws;

    # parse dotop name    # FIXME: precedence
    $self->[RHS] = $$token->next_skip_ws($token)->parse_dotop($token, $scope, $self->[META]->[LPREC])
        || return $self->missing_error( dotop => $token );

    # capture any args
    $self->[ARGS] = $$token->parse_args($token, $scope);

    if (DEBUG) {
        $self->debug("postop args: ", $self->[ARGS]);
        $self->debug("next token is ", $$token->next_skip_ws->token);
    }

    $self->debug("dot command as postop: $self->[LHS] dot $self->[RHS]") if DEBUG;
    
    # there may be other dotops following
    return $$token->skip_ws->parse_infix($self, $token, $scope, $self->[META]->[LPREC]);
}


sub text {
    $_[SELF]->debug("fetching text") if DEBUG;
    return $_[SELF]->variable($_[CONTEXT])->text;
}

sub value {
    $_[SELF]->debug("fetching value") if DEBUG;
    return $_[SELF]->variable($_[CONTEXT])->value;
}

sub variable {
    $_[SELF]->debug("fetching variable") if DEBUG;
    $_[SELF]->[LHS]->variable($_[CONTEXT])->dot(
        $_[SELF]->[RHS]->value($_[CONTEXT]),
        $_[SELF]->[ARGS]
            ? [$_[SELF]->[ARGS]->values($_[CONTEXT])]
            : ()
    );
}


sub source {
    sprintf(
        $_[SELF]->SOURCE_FORMAT,
        $_[SELF]->[TOKEN],
        $_[SELF]->[RHS]->source,
        $_[SELF]->[LHS]->source,
    )
}

1;
