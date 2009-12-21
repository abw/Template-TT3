package Template::TT3::Element::Operator::Dot;

use Template::TT3::Class::Element
    version   => 2.68,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::Binary
                  Template::TT3::Element',
    roles     => 'filename',        # dots allowed in filenames, e.g. foo.tt3
    view      => 'dot',
    constants => ':elements',
    constant  => {
        SOURCE_FORMAT => '%s%s%s', 
    };


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # Operator precedence - if our leftward binding precedence is less than
    # or equal to the precedence requested then we return the LHS.  
    # The 'or equal' part gives us left asociativity so that "a . b . c"
    # is parsed as "(a . b) . c"
    return $lhs 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # otherwise this operator has a higher precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # TODO: parse_dotop() should fetch word/expression, then we look for args
    $self->debug("asking $$token for dotop") if DEBUG;
    
    $self->[RHS] = $$token->parse_dotop($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( expression => $token );

    $self->[ARGS] = $$token->parse_args($token, $scope);

    $self->debug("DOT parse_infix() [$self->[LHS]] [$self->[RHS]] [$self->[ARGS]]") if DEBUG;
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub as_pair {
    my $self = shift;
    my $elems = $self->[META]->[ELEMS];
    my $name  = $elems->create(
        word => $self->[RHS]->name, $self->[POS]
    );
    $self->debug("Creating pair from dotop: $name") if DEBUG;
    return $elems->create(
        op_pair => "[=>]", $self->[POS], $name, $self
    );
}

sub as_lvalue {
    my ($self, $op, $rhs, $scope) = @_;
    return $op;
}


sub value {
    $_[SELF]->debug("fetching value()") if DEBUG;
    return $_[SELF]->variable($_[CONTEXT])->value($_[SELF]);
}

sub OLD_maybe {
    $_[SELF]->debug("maybe fetching value()") if DEBUG;
    return $_[SELF]->variable($_[CONTEXT])->maybe($_[SELF]);
}

sub variable {
    $_[SELF]->[LHS]->variable($_[CONTEXT])->dot(
        $_[SELF]->[RHS]->value($_[CONTEXT]),
        $_[SELF]->[ARGS]
            ? [$_[SELF]->[ARGS]->values($_[CONTEXT])]
            : undef,
        $_[SELF],
    );
}

sub left_edge {
    $_[SELF]->[LHS]->left_edge;
}

sub right_edge {
    $_[SELF]->[RHS]->right_edge;
}



1;
