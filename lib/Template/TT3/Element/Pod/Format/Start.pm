package Template::TT3::Element::Pod::Format::Start;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'pod_format_start',
    alias     => {
        skip_ws => 'next_skip_ws',
        value   => \&text,
        values  => \&text,
    },
    messages => {
        format_mismatch => 'Unexpected end of %s%s ... %s Pod format: %s',
    };


#our $FORMATS = {
#    B => 'Bold',
#    C => 'Code',
#    E => 'Entity',
#    I => 'Italic',
#    L => 'Link',
#    S => 'Space',
#    X => 'Index',
#    Z => 'Zero'
#};

our $ACTIONS = {
    L => \&split_link,
};


sub parse_expr {
    my ($self, $token, $scope) = @_;
    my $format = $self->[TOKEN];
    
    $self->debug("[format:$format] [start:$self->[LHS]] [end:$self->[RHS]]") if DEBUG;

    # skip any whitespace then parse the following block
    $self->[ARGS] = $$token->skip_ws($token)->parse_block($token, $scope)
        || return $self->fail_missing( $self->ARG_BLOCK => $token );

    # next token should be the matching end-of-format delimiter
    return $self->error_msg( format_mismatch => @$self[TOKEN, LHS, RHS], $$token->[TOKEN])
        unless $$token->is($self->[RHS], $token);

    return $self;
}


sub text {
    my ($self, $context) = @_;
    my $name   = $self->[TOKEN];
    my $body   = $self->[ARGS]->text($context);
    my $action = $ACTIONS->{ $name };
    my $params = $action
        ? $action->($self, $context, $name, $body) 
        : { body => $body };
    
    return $context->show(
        "pod.format.$name" => $params
    );
}


sub split_link {
    my ($self, $context, $name, $link) = @_;
    my $save = $link;
    my ($text, $page, $section);
    
    $self->debug("splitting link: $link") if DEBUG;
    
    $link =~ s/\n/ /g;   # undo line-wrapped tags

    # strip the sub-title and the following '|' char
    if ($link =~ s/^ ([^|]+) \| //x) {
        $text = $1;
    }

    # make sure sections start with a /
    $link =~ s|^"|/"|;

    if ($link =~ /^http/) {
        ($page, $section) = ($link, $1);
    }
    elsif ($link =~ m|^ (.*?) / "? (.*?) "? $|x) { # [name]/"section"
        ($page, $section) = ($1, $2);
    }
    elsif ($link =~ /\s/) {  # this must be a section with missing quotes
        ($page, $section) = ('', $link);
    }
    else {
        ($page, $section) = ($link, '');
    }

    # warning; show some text.
    $text = $save unless defined $text;

    return {
        body    => $link,
        link    => $link,
        text    => $text,
        page    => $page,
        section => $section,
    };
    
}


1;