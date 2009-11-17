package Template::TT3::Element::Role::Block;

use Template::TT3::Class 
    debug      => 0,
    version    => 2.718,
    constants  => ':elem_slots :eval_args',
    mixins     => 'as_block';


sub as_block {
    my ($self, $token, $scope, $prec) = @_;
    my (@exprs, $expr);

    $self->debug("as_block()") if DEBUG;
 
    # advance past opening block token
    $self->accept($token);

    # parse expressions
    my $block = $$token->as_exprs($token)
        || return $self->missing( block => $token );
    
    # check next token matches our FINISH token
    return $self->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH, $token );
    
    # return $block, not $self
    return $block;
}



1;
