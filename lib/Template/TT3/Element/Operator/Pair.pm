package Template::TT3::Element::Operator::Pair;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::InfixRight
                  Template::TT3::Element::Operator::Quiet
                  Template::TT3::Element',
    import    => 'class',
    view      => 'pair',
    as        => 'pair',
    constants => ':elements FORCE BLANK',
    alias     => {
        as_pair => 'self',          # I can do pairs, me
#        number => \&value,
    };


sub values {
    return (
        $_[SELF]->[LHS]->name( $_[CONTEXT] ),
        $_[SELF]->[RHS]->values( $_[CONTEXT] ),
    );
}


sub value {
    return [ 
        $_[SELF]->[LHS]->name( $_[CONTEXT] ),
        $_[SELF]->[RHS]->values( $_[CONTEXT] ),
    ]
}


sub text {
    return join(
        BLANK,
        $_[SELF]->[LHS]->name( $_[CONTEXT] ),
        $_[SELF]->[RHS]->text( $_[CONTEXT] ),
    );
}


sub pairs {
    return $_[SELF]->[LHS]->name( $_[CONTEXT] )     # fetch LHS as a name
        => $_[SELF]->[RHS]->value( $_[CONTEXT] );   # fetch RHS as a value
}


sub params {
    # ($self, $context, \@positional_args, \%named_params)
    push(
        @{$_[2]},
        $_[SELF]->[LHS]->name( $_[CONTEXT] ),
        $_[SELF]->[RHS]->value( $_[CONTEXT] )
    );
}


1;


