package Template::TT3::Element::Operator::Pair;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::InfixRight
                  Template::TT3::Element::Operator::Assignment
                  Template::TT3::Element',
    import    => 'class',
    view      => 'pair',
    constants => ':elements FORCE BLANK',
    alias     => {
#        number => \&value,
    };


sub OLD_parse_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    $self->[LHS] = $lhs;
    $self->[RHS] = $$token->next_skip_ws($token)
        ->parse_expr($token, $scope, $self->[META]->[LPREC], FORCE)
        || return $self->missing( expression => $token );

    return $$token->skip_ws->parse_postop($self, $token, $scope, $prec);
}



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


