package Template::TT3::Element::Command::Is;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    alias      => {
        value  => \&text,
        values => \&text,
    };

# hmm... problem with generators here... we really want to generate
# 'do' as a keyword when called with with token generators.

sub generate {
    $_[GENERATOR]->generate_keyword(
        $_[SELF]->[TOKEN],
        $_[SELF]->[EXPR],
    );
}

sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

#    $self->debug("IS as_expr($prec)  (self prec: $self->[META]->[LPREC])");

    # Operator precedence.  If the $force flag is set (indicating that we're
    # on the RHS of an assignment operator which really, REALLY wants an 
    # expression) then we continue even if our precedence is lower than that
    # specified
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token past keyword
    $self->accept($token);
    
    # parse block
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );
    
    return $self;
}


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store LHS and advance token past keyword
    $self->[LHS] = $lhs;
    $$token = $self->[NEXT];
    
    # parse block
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );
    
    # TODO: return assign node
    return $self;
}


sub text {
    # if an 'is' command has a LHS then it's like an assignment: foo is { xxx }
    # otherwise it's just an anonymous block container: is { xxx }
    $_[SELF]->[LHS]
        ? $_[SELF]->[LHS]
            ->variable( $_[CONTEXT] )
            ->set( $_[SELF]->[RHS]->text( $_[CONTEXT] ) )->BLANK
        : $_[SELF]->[RHS]->text( $_[CONTEXT] );
}


1;