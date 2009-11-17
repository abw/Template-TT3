
package Template::TT3::Element::Command::Raw;

#barf;

use Template::TT3::Elements::Structure;


use Template::TT3::Class
    version    => 3.00,
    base       => 'Template::TT3::Element::Block Template::TT3::Element::Command',
    view       => 'raw',
    constants  => ':elem_slots :eval_args',
    alias      => {
        value  => 'text',
        values => 'text',
    };


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token past keyword
    $self->accept($token);
    
    # parse block
    $self->[EXPR] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );
    
    return $self;
}


sub text {
    $_[SELF]->[EXPR]->text( $_[CONTEXT] );
}


1;
