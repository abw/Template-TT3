package Template::TT3::Element::Command::For;

use Template::TT3::Iterator;
use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'for',
    modules    => 'ITERATOR_MODULE',
    constants  => ':elements ARRAY',
    constant   => {
        ITEM         => 'item',
        IN           => 'in',
        SEXPR_FORMAT => "<for:\n  <expr:\n    %s\n  >\n  <body:\n    %s\n  >\n>",
        FOLLOW       => {
            map { $_ => 1 }
            qw( elsif else )
        },
    },
    alias      => {
        value  => \&text,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;
    my $lprec = $self->[META]->[LPREC];

    return undef
        if $prec && ! $force && $lprec <= $prec;

    $self->advance($token);

    $self->[FRAGMENT] = $$token->parse_fragment($token, $scope);
    
    my $expr = $$token->parse_expr($token, $scope, $lprec)
        || return $self->fail_missing( expression => $token );

    # if the next token is 'in' then the LHS is the target data
    if ($$token->skip_ws($token)->is(IN, $token)) {
        $self->[ARGS] = $expr;
        $self->[EXPR] = $$token->parse_expr($token, $scope, $lprec)
            || return $self->fail_missing( expression => $token );
    }
    else {
        $self->[EXPR] = $expr;
    }

    $self->[BLOCK] = $$token
        ->parse_body($token, $scope, $self, $self->FOLLOW)
        || return $self->fail_missing( block => $token );

#    return $self;
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;
    my $lprec = $self->[META]->[LPREC];

    return $lhs
        if $prec && $lprec <= $prec;

    $self->advance($token);

    $self->[BLOCK] = $lhs;

    my $expr = $$token->parse_expr($token, $scope, $lprec)
        || return $self->fail_missing( expression => $token );
    
    # if the next token is 'in' then the LHS is the target data
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


sub else_block {
    return @_ == 1
        ? $_[SELF]->[BRANCH]
        : $_[SELF]->[BRANCH] = $_[1];
}        


sub values {
    my ($self, $context) = @_;
    my ($target, @values);

    # evaluate the expression that gives us a list
    my $value = $self->[EXPR]->value($context);
    
    return $self->[EXPR]->fail_undef_data
        unless defined $value;
    
    $value = [ $value ] 
        unless ref $value eq ARRAY;
    
    return $self->else_values($context)
        unless @$value;

    # this is the block we're going to repeatedly process
    my $block = $self->[BLOCK];

    # localise context for our 'item' (or other) iteration variable
    $context = $context->with;

    # if the user didn't specify an 'x' like 'for x in y' then we use 'item'
    if ($target = $self->[ARGS]) {
        $target = $target->variable($context);
    }
    else {
        $target = $context->use_var(ITEM);
    }
    
    # repeat for each item
    # FIXME: quick hack - don't trample on loop
    my $iter = $self->ITERATOR_MODULE->new($value);
    $context->set( loop => $iter );
    
    
    foreach my $item (@$value) {
        # quick hack
        $iter->one;
        $target->set($item);
        push(@values, $block->values($context));
    }

    return @values;
}


sub text {
    # Hmmm... should we re-implement this in full so we can call else_text()
    # instead of else_values()?
    join('', $_[SELF]->values($_[CONTEXT]));
}


sub else_values {
    return $_[SELF]->[BRANCH]
         ? $_[SELF]->[BRANCH]->values($_[CONTEXT])
         : ()
}


sub else_text {
    return $_[SELF]->[BRANCH]
         ? $_[SELF]->[BRANCH]->text($_[CONTEXT])
         : ()
}


sub sexpr {
    my $self   = shift;
    my $format = shift || $self->SEXPR_FORMAT;
    my $expr   = $self->[LHS]->sexpr;
    my $body   = $self->[RHS]->sexpr;
    for ($expr, $body) {
        s/\n/\n    /gsm;
    }
    sprintf(
        $format,
        $expr,
        $body
    );
}
    




1;
