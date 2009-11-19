package Template::TT3::Element::Control::Tags;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elements DOT',
    constant   => {
        SKIP_WORDS => {
            map { $_ => 1 }
            qw( = are ) 
        },
    },
    alias      => {
        text   => \&value,
        values => \&value,
    },
    messages => {
        tags_undef => 'Undefined value returned by %s expression: %s',
        no_scanner => 'Scanner is not accessible to %s control.',
    };


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # skip over the TAGS keyword and any whitespace
    $$token->next_skip_ws($token);

    # if the next token is a '.' then we parse a single word after it.
    # e.g. TAGS.inline
    if ($$token->is(DOT, $token)) {
        $self->[LHS] = $$token->as_word($token, $scope)
            || return $self->missing( 'tag name' => $token );

        $self->debug('got dotted TAGS: ', $self->[RHS]->[TOKEN]) if DEBUG;
    }

    # skip over '=' or 'are', so "TAGS are ..." (for example) are
    # treated the same as just "TAGS ..."
    $$token->in(SKIP_WORDS, $token);
    
    # parse the next expression    
    $self->[RHS] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );
    
    return $self;
}


sub value {
    my ($self, $context) = @_;
    my $expr = $self->[RHS];
    my $tags = $expr->value($context);
    
    return $self->error_msg( tags_undef => $self->[TOKEN], $expr->source )
        unless defined $tags;

    # If we had a dotted name after the TAGS, e.g. TAGS.comment then the 
    # name expression will be in $self->[LHS].  In this case we create a 
    # hash array containing the single item, e.g. { comment => ... }
    $tags = { $self->[LHS]->value($context) => $tags } 
        if $self->[LHS];
        
    $self->debug("Setting TAGS: $tags") if DEBUG;
    
    my $scanner = $context->scope->scanner
        || return $self->error_msg( no_scanner => $self->[TOKEN] );
        
    $scanner->tags($tags);
    
    return ();
}


1;