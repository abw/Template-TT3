package Template::TT3::Element::Control::Tags;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    constant   => {
        SKIP_WORDS => {
            map { $_ => 1 }
            qw( = is are ) 
        },
    },
    alias      => {
        text   => \&value,
        values => \&value,
    },
    messages => {
        tags_undef => 'Undefined value returned by %s expression: %s',
    };

sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # skip over the TAGS keyword and any whitespace
    $$token->next_skip_ws($token);

    # skip over '=', 'is' or 'are', so "TAGS are ..." (for example) are
    # treated the same as just "TAGS ..."
    $$token->next($token)
        if $$token->in( SKIP_WORDS );
        
    $self->[EXPR] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );
    
    return $self;
}

sub value {
    my ($self, $context) = @_;
    my $expr = $self->[EXPR];
    my $tags = $expr->value($context)
        || return $self->error_msg( tags_undef => $self->[TOKEN], $expr->source );
        
    $self->debug("evaluating TAGS: $tags");
    
    return ();
}

1;