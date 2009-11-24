package Template::TT3::Element::Command::With;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'with',
    constants  => ':elements',
    constant   => {
        SOURCE_FORMAT => '%s %s { %s }',
    },
    as         => 'args_block_expr',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS operand as block and advance token past keyword
    $self->[BLOCK] = $lhs;
    $self->advance($token);

    # parse parameter list into ARGS
    $self->[ARGS] = $$token->parse_params($token, $scope);
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub text {
    my ($self, $context) = @_;
    
    return $self->[BLOCK]->text( 
        $context->with(
            $self->[ARGS]->pairs($context)
        ) 
    );
}



1;