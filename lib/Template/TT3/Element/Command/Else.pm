package Template::TT3::Element::Command::Else;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'else',
    constants  => ':elements',
    alias      => {
        value  => \&text,
    };


sub parse_follow {
    my ($self, $block, $token, $scope, $parent) = @_;

    # advance token
    $self->advance($token);
    
    # parse block following the expression, and any follow-on blocks after that
    $self->[RHS] = $$token->parse_body($token, $scope, $self)
        || return $self->missing_error( block => $token );

    # add $self as follow-on block of $parent
    # TODO: decide on the correct name: follow/else
    $parent->else_block($self);
    
    # we return the original block that precedes us
    return $block;
}


sub text {
    $_[SELF]->[RHS]->text($_[CONTEXT]);
}


sub values {
    $_[SELF]->[RHS]->values($_[CONTEXT]);
}



1;
