package Template::TT3::Element::Command::Into;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    as         => 'name_block_expr',
    view       => 'into',
    constants  => ':elements',
    alias      => {
        values => \&text,
        value  => \&text,
    };

sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS operand as block and advance token past keyword
    $self->[BLOCK] = $lhs;
    $self->advance($token);

    # parse filename into EXPR
    $self->[EXPR] = $$token
        ->next_skip_ws($token)
        ->parse_filename($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( filename => $token );

    # save the scope in case we need to lookup blocks later
    $self->[ARGS] = $scope;
    
    # parse any other infix operators
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub text {
    my ($self, $context) = @_;

    # Ask our filename expression to fetch a template and then fill it
    # with a local context defining the 'content' variable to be the 
    # text generated from evaluating our block.
    
    return $self->[EXPR]
        ->template(
            $context,
            $self->[ARGS]
        )
        ->fill_in(
            $context->with(
                content => $self->[BLOCK]->text(
                    $context
                )
            )
        );
}

1;
