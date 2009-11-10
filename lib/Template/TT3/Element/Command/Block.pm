package Template::TT3::Element::Command::Block;

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
    $_[GENERATOR]->generate_block(
        $_[SELF]->[TOKEN],
        $_[SELF]->[EXPR],
    );
}

sub as_expr {
    my ($self, $token, $scope, $prec) = @_;

    # operator precedence
    return undef
        if $prec && $self->[META]->[LPREC] <= $prec;

    # advance token past keyword
    $$token = $self->[NEXT];
    
    # parse block
    $self->[EXPR] = $$token->as_block($token, $scope)
        || return $self->error("Missing block after $self->[TOKEN]");

    $self->debug("next token: ", $$token->token);
    
    return $self;
}

sub text {
    $_[SELF]->[EXPR]->text($_[CONTEXT]);
}


1;
