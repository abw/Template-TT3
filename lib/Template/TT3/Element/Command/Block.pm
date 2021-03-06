package Template::TT3::Element::Command::Block;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    utils      => 'tt_params',
    view       => 'blockdef',
    constants  => ':elements BLANK',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Check precedence and advance past 'block' keyword
    $self->advance_expr($token, $scope, $prec, $force)
        || return;

    if ($self->[ARGS] = $$token->parse_signature($token, $scope, $self)) {
        # We've got a parenthesised function signature immediately following 
        # the block keyword, e.g. hello = block(name) { 'Hello ' name }
    }
    elsif ($self->[EXPR] = $$token->skip_ws($token)->parse_filename($token, $scope)) {
        # We've got a name following the block keyword which might also have 
        # a function signature
        $self->[ARGS] = $$token->parse_signature($token, $scope, $self->[EXPR]);
    }
    
    # skip any whitespace then parse the following block
    $self->[BLOCK] = $$token->skip_ws($token)->parse_body($token, $scope, $self)
        || return $self->fail_missing( $self->ARG_BLOCK => $token );

    if ($self->[EXPR]) {
        # this is a named block so we need to define a block at compile time
        $self->debug("declaring block: $self->[EXPR] in scope: $scope") if DEBUG;
        
        my $name = $self->[EXPR]->value( $scope->context );
        
        if ($self->[ARGS]) {
            # TODO: I think named blocks can't have args.  They're creating
            # runtime templates which need a context to work in.  Hmmm...
            # unless they inherit the context of the point at which they're
            # defined.  We'll just throw an error for now...

            $self->not_implemented('named block with arguments');
            
            # old code
            #$scope->{ blocks }->{ $name } = {
            #    source => $scope->{ source },
            #    name   => $name,
            #    code   => sub {
            #        my $context = shift;
            #        $self->debug("RUNNING BLOCK WITH ARGS!") if DEBUG;
            #        my $params = tt_params($self, $self->[ARGS]->signature, undef, @_);
            #        $self->debug("got params: $params") if DEBUG;
            #        return "TODO: real block subs";
            #    },
            #};
        }
        else {
            # current way pushes block into scope... but this will break when
            # we start using nested lexical scopes in a template.
            $scope->{ blocks }->{ $name } = {
                source => $scope->{ source },
                name   => $name, 
                block  => $self->[BLOCK],
            };

            # the new way should call a method on the scope which will walk
            # up the scope chain until it find a template object to register
            # the block with.
            
            #$scope->block( 
            #    $name => {
            #        source => $scope->{ source },
            #        name   => $name, 
            #        block  => $self->[BLOCK],
            #    }
            #);

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

        # TODO: pre-compute this at compile time
        my $sign = $self->[ARGS]->signature;

        return sub {
            return $self->[BLOCK]->text(
                $context->with(
                    tt_params($self, $sign, undef, @_)
                )
            );
        };
    }
        
    return $self->[BLOCK]->text( $context );
}

1;
