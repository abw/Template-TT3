package Template::TT3::View::Tree::Sexpr;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tree',
    auto_can  => 'can_view',
    constants => ':elements',
    constant  => {
        APPLY_FORMAT    => "<apply:%s%s>",
        ARGS_FORMAT     => "<args:%s>",
        BINARY_FORMAT   => '<binary:<op:%s>%s%s>', 
        BLOCK_FORMAT    => '<block:%s>',
        DOT_FORMAT      => '<dot:%s%s%s>',
        DQUOTE_FORMAT   => '<dquote:%s>',
        ELEMENT_FORMAT  => "<%s%s>%s</%s>",
        FILENAME_FORMAT => '<filename:%s>',
        KEYWORD_FORMAT  => '<keyword:%s>',
        NUMBER_FORMAT   => '<number:%s>',
        POSTFIX_FORMAT  => '<postfix:<op:%s>%s>', 
        PREFIX_FORMAT   => '<prefix:<op:%s>%s>', 
        SQUOTE_FORMAT   => '<squote:%s>',
        TEXT_FORMAT     => '<text:%s>',
        UNARY_FORMAT    => '<unary:<op:%s>%s>', 
        VARIABLE_FORMAT => '<variable:%s>', 
        WORD_FORMAT     => '<word:%s>',
    };


sub OLD_construct {
    my ($self, $type, $elem) = @_;
    sprintf(
        '<%s:%s>',
        $type,
        $elem->[EXPR]->view($self)
    );
}


sub view_number {
    my ($self, $number) = @_;
    return sprintf(
        $self->NUMBER_FORMAT,
        $number->token
    );
}


sub view_text {
    my ($self, $text) = @_;
    return sprintf(
        $self->TEXT_FORMAT,
        $text->token
    );
}


sub view_word {
    my ($self, $text) = @_;
    return sprintf(
        $self->WORD_FORMAT,
        $text->token
    );
}


sub view_keyword {
    my ($self, $text) = @_;
    return sprintf(
        $self->KEYWORD_FORMAT,
        $text->token
    );
}


sub view_squote {
    my ($self, $squote) = @_;
    return sprintf(
        $self->SQUOTE_FORMAT,
        $squote->token,
    );
}


sub view_dquote {
    my ($self, $dquote) = @_;
    my $body;
    
    if ($dquote->[BLOCK]) {
        if ($body = $dquote->[BLOCK]->view($self)) {
            $body =~ s/^/  /gsm;
            $body = "\n" . $body . "\n";
        }
    }
    elsif ($dquote->[EXPR]) {
        $body = $dquote->[EXPR];
    }
    else {
        $body = $dquote->[TOKEN];
    }

    return sprintf(
        $self->DQUOTE_FORMAT,
        $body,
    );
}


sub view_filename {
    my ($self, $filename) = @_;
    return sprintf(
        $self->FILENAME_FORMAT,
        $filename->filename,
    );
}


sub view_block {
    my ($self, $block, $format) = @_;
    my $body = join(
        "\n", 
        map { $_->view($self) }
        $block->expressions
    );
    $body =~ s/^/  /gsm if $body;
    $format ||= $self->BLOCK_FORMAT;
    sprintf(
        $format,
        $body ? ("\n" . $body . "\n") : ''
    );
}


sub view_args {
    my ($self, $args) = @_;
    return $self->view_block($args, $self->ARGS_FORMAT);
}


sub view_variable {
    my ($self, $var) = @_;
    
    if ($var->[ARGS]) {
        # shouldn't ever have args as these are now handled by a separate
        # function application element
        return $self->error("unexpected args in variable");
    }

    sprintf(
        $self->VARIABLE_FORMAT,
        $var->[TOKEN],
    );
}
    

sub view_apply {
    my ($self, $apply) = @_;
    my $name = $apply->[EXPR]->sexpr;
    my $args = $apply->[ARGS] ? $self->view_args( $apply->[ARGS] ) : '<args:>';
    for ($name, $args) {
        s/^/  /gsm;
    }
    sprintf(
        $self->APPLY_FORMAT,
        "\n" . $name,
        "\n" . $args . "\n"
    );
}


sub view_unary {
    my ($self, $op) = @_;
    sprintf(
        $self->UNARY_FORMAT, 
        $op->[TOKEN],
        $op->[LHS]
            ? $op->[LHS]->view($self)
            : $op->[RHS]->view($self)
    );
}


sub view_prefix {
    my ($self, $op) = @_;
    sprintf(
        $self->PREFIX_FORMAT, 
        $op->[TOKEN],
        $op->[RHS]->view($self)
    );
}


sub view_postfix {
    my ($self, $op) = @_;
    sprintf(
        $self->POSTFIX_FORMAT, 
        $op->[TOKEN],
        $op->[LHS]->view($self)
    );
}


sub view_binary {
    my ($self, $op) = @_;
    sprintf(
        $self->BINARY_FORMAT, 
        $op->[TOKEN],
        $op->[LHS]->sexpr,
        $op->[RHS]->sexpr,
    );
}



sub view_dot {
    my ($self, $dot) = @_;
    my $lhs  = $dot->[LHS]->view($self);
    my $rhs  = $dot->[RHS]->view($self);
    my $args = $dot->[ARGS];
    $args = $args 
        ? $self->view_args($args)
        : '<args:>';
    for ($lhs, $rhs, $args) {
        next unless length;
        s/^/  /gsm;
    }
    sprintf(
        $self->DOT_FORMAT,
        "\n" . $lhs,
        "\n" . $rhs,
        "\n" . $args . "\n"
    );
}







    
sub view_list {
    $_[SELF]->construct( list => $_[1] );
}


sub view_hash {
    $_[SELF]->construct( hash => $_[1] );
}

sub view_parens {
    $_[SELF]->construct( hash => $_[1] );
}


sub block_sexpr_TODO {
    my $self   = shift;
    my $format = shift || $self->SEXPR_FORMAT;
#        SEXPR_FORMAT  => "<block:%s>",

    my $body   = join(
        "\n",
        map { $_->sexpr } 
        @{ $self->[EXPR] }
    );
    $body =~ s/^/  /gsm if $body;
    sprintf(
        $format,
        $body ? ("\n" . $body . "\n") : ''
    );
}



sub can_view {
    return undef;
    
    my ($self, $name) = @_;
    my $class = ref $self || $self;
    my $method = "view_$name()";

    return sub {
        "No $method method defined in $class";
    }
}


1;