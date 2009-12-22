package Template::TT3::Element::Command::For;

use Template::TT3::Iterator;
use Template::TT3::Class::Element
    version    => 2.68,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'for',
    follow     => 'elsif else',
    modules    => 'ITERATOR_MODULE',
    constants  => 'ARRAY BLANK',
    constant   => {
        ITEM   => 'item',
        IN     => 'in',
    },
    alias      => {
        value  => \&text,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;
    my $lprec = $self->[META]->[LPREC];

    # operator precedence
    return undef
        if $prec && ! $force && $lprec <= $prec;

    # advance token past keyword
    $$token = $self->[NEXT];

    # there may be a #fragment attached to the keyword
    $self->[FRAGMENT] = $$token->parse_fragment($token, $scope);
    
    # then we must have an expression
    my $expr = $$token->parse_expr($token, $scope, $lprec)
        || return $self->fail_missing( expression => $token );

    # if the next token is 'in' then the LHS is the target item and the
    # source data should follow, e.g. for x in y, otherwise it's just data
    if ($$token->skip_ws($token)->is(IN, $token)) {
        $self->[ARGS] = $expr;
        $self->[EXPR] = $$token->parse_expr($token, $scope, $lprec)
            || return $self->fail_missing( expression => $token );
    }
    else {
        $self->[EXPR] = $expr;
    }

    # then we must have a block
    $self->[BLOCK] = $$token
        ->parse_body($token, $scope, $self, $self->FOLLOW)
        || return $self->fail_missing( block => $token );

    # delegate onto the next token to see if it's an infix operator
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;
    my $lprec = $self->[META]->[LPREC];

    # operator precedence
    return $lhs
        if $prec && $lprec <= $prec;

    # advance token past keyword
    $$token = $self->[NEXT];

    # save the preceding expression as our body block
    $self->[BLOCK] = $lhs;

    # parse either 'data' or 'item in data', as per parse_expr()
    my $expr = $$token->parse_expr($token, $scope, $lprec)
        || return $self->fail_missing( expression => $token );
    
    if ($$token->skip_ws($token)->is(IN, $token)) {
        $self->[ARGS] = $expr;
        $self->[EXPR] = $$token->parse_expr($token, $scope, $lprec)
            || return $self->fail_missing( expression => $token );
    }
    else {
        $self->[EXPR] = $expr;
    }
    
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub evaluate {
    my ($self, $method, $context) = @_;
    my ($value, $block, $target, $iter, @values);

    # TODO: we should give objects a chance to provide an iterator, e.g.
    # tt_iterator(), or provide us with a list of values via tt_list().

    # evaluate the expression that gives us a list
    $value = $self->[EXPR]->value($context);

    if (defined $value) {
        # upgrade a single item to a list
        $value = [ $value ] 
            unless ref $value eq ARRAY;

        # short-circuit to the else block (if there is one) if list is empty
        return $self->else_values($context)
            unless @$value;
    }
    elsif ($self->[BRANCH]) {
        # TODO: not sure if we should silently skip to the else block when
        # the source data is undefined...
        return $self->else_values($context);
    }
    else {
        return $self->[EXPR]->fail_data_undef;
    }

    # this is the block we're going to repeatedly process
    $block = $self->[BLOCK];
    
    # and this is the method we're going to call on it
    $method = $block->can($method)
        || return $self->error_msg( bad_method => evaluation => $method );

    # localise context for our 'item' (or other) iteration variable
    $context = $context->with;

    # default the target item to 'item'
    if ($target = $self->[ARGS]) {
        $target = $target->variable($context);
    }
    else {
        $target = $context->use_var(ITEM);
    }
    
    # create an iterator and bind it to the 'loop' variable
    $iter = $self->ITERATOR_MODULE->new($value);
    $context->set( loop => $iter );

    # TODO: let the iterator drive
    foreach my $item (@$value) {
        # quick hack
        $iter->one;
        $target->set($item);
        push(@values, $method->($block, $context));
    }

    return @values;
}


sub values {
    shift->evaluate( values => @_ );
}


sub text {
    join(
        BLANK,
        shift->evaluate( text => @_ )
    )
}


sub else_block {
    return @_ == 1
        ? $_[SELF]->[BRANCH]
        : $_[SELF]->[BRANCH] = $_[1];
}        


sub else_values {
    return $_[SELF]->[BRANCH]
         ? $_[SELF]->[BRANCH]->values($_[CONTEXT])
         : ()
}


sub else_text {
    return $_[SELF]->[BRANCH]
         ? $_[SELF]->[BRANCH]->text($_[CONTEXT])
         : BLANK;
}

# TODO: what about pairs?
    


1;
