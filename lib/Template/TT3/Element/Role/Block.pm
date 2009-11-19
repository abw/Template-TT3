package Template::TT3::Element::Role::Block;

use Template::TT3::Class 
    debug      => 0,
    version    => 2.718,
    constants  => ':elements',
    mixins     => 'as_block';


sub as_block {
    my ($self, $token, $scope, $parent, $follow) = @_;
    my (@exprs, $expr);
    
    # Optional 4th argument is a reference to the parent but default to $self.
    # We report all errors from this perspective.
    $parent ||= $self;

    $self->debug("as_block()") if DEBUG;
 
    # advance past opening block token
    $self->accept($token);

    # parse expressions
    my $block = $$token->as_exprs($token, $scope)
        || return $parent->missing( $self->ARG_BLOCK, $token );

    # check next token matches our FINISH token
    return $parent->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH, $token );
#       unless $$token->is( $self->FINISH );

#    $block->[FOLLOW] = $$token->follow($block, $token, $scope
    
    
    # return $block, not $self
    return $block;
}



1;
