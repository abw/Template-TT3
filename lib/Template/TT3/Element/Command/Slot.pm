package Template::TT3::Element::Command::Slot;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
#    as         => 'name_block_expr',
    constants  => ':elements',
    alias      => {
        values => \&text,
        value  => \&text,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance past the keyword and whitespace then parse a filename
    $self->[EXPR] = $$token
        ->next_skip_ws($token)
        ->parse_filename($token, $scope, $self->[META]->[LPREC])
        || return $self->fail_missing( $self->ARG_NAME => $token );

    # parse a block following the expression
    $self->[BLOCK] = $$token
        ->parse_body($token, $scope)
        || return $self->fail_missing( $self->ARG_BLOCK => $token );

    # evaluate the slots name
    my $name = $self->[ARGS] = $self->[EXPR]->value( $scope->context );

    # add the slot entry to the scope
    $scope->{ slots }->{ $name } = {
        source => $scope->{ source },
        name   => $name, 
        block  => $self->[BLOCK],
    };

    return $self;
}


sub parse_infix {
    # not sure if it makes sense for slot to work in side-effect form...
    # need to try it out first
    shift->todo;
}


sub text {
    my ($self, $context) = @_;

    my $name     = $self->[ARGS];
    my $visiting = $context->visiting;
    my (@scopes, $scope, $block, $visitor);
    
    $self->debug(
        "slot is visiting: ", 
        join(', ', @$visiting)
    ) if DEBUG;

    # look upwards through the caller stack for a block
    foreach $visitor (reverse @$visiting) {
        next unless $scope = $visitor->{ scope };
        push(@scopes, $scope);
        
#        $self->debug("SLOT found scope: ", $self->dump_data($scope));

        if ($block = $scope->{ blocks }->{ $name }) {
            $self->debug(
                "slot found $name block: ", 
                $self->dump_data($block)
            ) if DEBUG;
            last;
        }
    }
    
    # now walk back down the caller stack looking for a slot
    unless ($block) {
        foreach $scope (reverse @scopes) {
            if ($block = $scope->{ slots }->{ $name }) {
                $self->debug(
                    "slot found $name slot: ", 
                    $self->dump_data($block)
                ) if DEBUG;
                last;
            }
        }
    }

    # fetch the block element from the block/scope found above, or use
    # the default
    $block = $block
        ? $block->{ block }
        : $self->[BLOCK];

    $self->debug("slot got block expression: $block") if DEBUG;

    # TODO: this should do a proper fill() to get the template block on 
    # the visiting stack... Need to think about that...

    return $block->text(
        $context
    );
}

# For reference, this is what 'into' does    
#    return $self->[EXPR]
#        ->template(
#            $context,
#            $self->[ARGS]
#        )
#        ->fill_in(
#            $context->with(
#                content => $self->[BLOCK]->text(
#                    $context
#                )
#            )
#        );


1;
