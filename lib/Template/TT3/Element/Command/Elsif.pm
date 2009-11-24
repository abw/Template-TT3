package Template::TT3::Element::Command::Elsif;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'elsif',
    constants  => ':elements',
    constant   => {
        SEXPR_FORMAT => "<elsif:\n  <expr:\n    %s\n  >\n  <body:\n    %s\n  >\n>",
        FOLLOW       => {
            map { $_ => 1 }
            qw( elsif else )
        },
    },
    alias      => {
        value  => \&text,
    };


sub parse_follow {
    my ($self, $block, $token, $scope, $parent) = @_;

    # advance token
    $self->advance($token);
    
    # parse expression following
    $self->[LHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( expression => $token );

    # parse block following the expression, and any follow-on blocks after that
    $self->[RHS] = $$token->parse_body($token, $scope, $self, $self->FOLLOW)
        || return $self->missing( block => $token );

    # add $self as follow-on block of $parent
    # TODO: decide on the correct name: follow/else
    $parent->else_block($self);
    
    # we return the original block that precedes us
    return $block;
}


sub else_block {
    return @_ == 1
        ? $_[SELF]->[ELSE]
        : $_[SELF]->[ELSE] = $_[1];
}        


sub text {
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



1;
