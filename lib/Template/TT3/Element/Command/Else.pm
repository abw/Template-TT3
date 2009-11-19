package Template::TT3::Element::Command::Else;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    view       => 'else',
    constants  => ':elements',
    alias      => {
        value  => \&text,
    };


sub as_follow {
    my ($self, $block, $token, $scope, $parent) = @_;

    # advance token
    $self->accept($token);
    
    # parse block following the expression, and any follow-on blocks after that
    $self->[RHS] = $$token->as_block($token, $scope, $self)
        || return $self->missing( block => $token );

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
