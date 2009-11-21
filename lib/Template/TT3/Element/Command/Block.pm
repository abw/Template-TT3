package Template::TT3::Element::Command::Block;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    utils      => 'tt_params',
    constants  => ':elements BLANK',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Check precedence and advance past 'block' keyword
    $self->accept_expr($token, $scope, $prec, $force)
        || return;

    if ($self->[ARGS] = $$token->as_signature($token, $scope, $self)) {
        # We've got a parenthesised function signature immediately following 
        # the block keyword, e.g. hello = block(name) { 'Hello ' name }
    }
    elsif ($self->[EXPR] = $$token->skip_ws($token)->as_filename($token, $scope)) {
        # We've got a name following the block keyword which might also have 
        # a function signature
        $self->[ARGS] = $$token->as_signature($token, $scope, $self->[EXPR]);
    }
    
    # skip any whitespace then parse the following block
    $self->[BLOCK] = $$token->skip_ws($token)->as_block($token, $scope, $self)
        || return $self->missing( $self->ARG_BLOCK => $token );

    if ($self->[EXPR]) {
        # this is a named block so we need to define a block at compile time
        $self->debug("declaring block: $self->[EXPR] in scope: $scope") if DEBUG;
        
        my $name = $self->[EXPR]->value( $scope->context );
        
        if ($self->[ARGS]) {
            # TODO: I think named blocks can't have args.  They're creating
            # runtime templates which need a context to work in.  Hmmm...
            # unless they inherit the context of the point at which they're
            # defined....
            
            $scope->{ blocks }->{ $name } = sub {
                my $context = shift;
                $self->debug("RUNNING BLOCK WITH ARGS!") if DEBUG;
                my $params = tt_params($self, $self->[ARGS]->signature, undef, @_);
                $self->debug("got params: $params") if DEBUG;
                return "TODO: real block subs";
            };
        }
        else {
            $scope->{ blocks }->{ $name } = sub {
                my $context = shift;
                $self->debug("RUNNING BLOCK WITH NO ARGS!");
                return "TODO: real block subs";
            };
        }
            
        $self->debug("added blocks: ", $self->dump_data($scope->{ blocks }))
            if DEBUG;
    }
        
    return $self;
}


sub text {
    my ($self, $context) = @_;

    if ($self->[EXPR]) {
        $self->debug(
            "Block has a name (", 
            $self->[EXPR]->value($context),
            ") no runtime content generated"
        ) if DEBUG;
        
        return BLANK;
    }
    
    if ($self->[ARGS]) {
        $self->debug(
            "Block has arguments, generating runtime subroutine (", 
            $self->dump_data($self->[ARGS]),
            ")"
        ) if DEBUG;

        return sub {
            $self->debug("Running block with args: ", $self->dump_data($self->[ARGS]))
                if DEBUG;
            my $params = tt_params($self, $self->[ARGS]->signature, undef, @_);
            $self->debug("got params: ", $self->dump_data($params)) if DEBUG;
            $context->{ variables }->set_vars($params);
            return $self->[BLOCK]->text( $context );
        };
    }
        
        # this is a named block;
 #       if ($self->[ARGS]) {
            
    
    # If the block has a name then it is purely declarative and generates
    # no output at runtime, otherwise it's a runtime block.
#    $_[SELF]->debug("BLOCK HAS NAME: ", $_[SELF]->[EXPR]->value($_[CONTEXT]))
#        if $_[SELF]->[EXPR];
#    $_[SELF]->debug("BLOCK HAS ARGS: ", $_[SELF]->dump_data($_[SELF]->[ARGS]))
#        if $_[SELF]->[ARGS];
        
    return $self->[BLOCK]->text( $context );
}

1;
