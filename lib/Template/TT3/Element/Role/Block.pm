package Template::TT3::Element::Role::Block;

use Template::TT3::Class 
    debug      => 0,
    version    => 2.718,
    constants  => ':elements',
    mixins     => 'parse_body';


sub parse_body {
    my ($self, $token, $scope, $parent, $follow) = @_;
    my (@exprs, $expr);
    
    # Optional 4th argument is a reference to the parent but default to $self.
    # We report all errors from this perspective.
    $parent ||= $self;

    $self->debug("parse_body()") if DEBUG;
 
    # advance past opening block token
    $self->advance($token);

    # parse expressions
    my $block = $$token->parse_block($token, $scope)
        || return $parent->missing_error( $self->ARG_BLOCK, $token );

    # check next token matches our FINISH token
    return $parent->missing_error( $self->FINISH, $token)
        unless $$token->is( $self->FINISH, $token );
#       unless $$token->is( $self->FINISH );

#    $block->[FOLLOW] = $$token->follow($block, $token, $scope
    
    
    # return $block, not $self
    return $block;
}



1;
