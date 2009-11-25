package Template::TT3::Element::HTML;

use Template::TT3::Type::Hash 'hash_html_attrs';
use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    import     => 'class',
    utils      => 'self_params',
    view       => 'html_element',
    constants  => ':elements CMD_PRECEDENCE SPACE',
    constant   => {
        CLASS_DOT    => '.',
        ID_HASH      => '#',  
        HTML_ELEMENT => 'html_%s',
        ATTR_PARENS  => {
            '[' => ']',
            '(' => ')',
        },
    },
    exports    => {
        any    => '@ELEMENT_NAMES element_names elements element',
    },
    messages   => {
        dup_id => 'HTML element id specified twice in %s: %s / %s',
    };


our %ELEMENT_COMMANDS;
our %ELEMENT_NAMES = 
    map { $_ => $_ }
    qw(
        a abbr acronym address applet area 
        b base basefont bdo big blockquote body br button caption 
        center cite code col colgroup 
        dd del dfn dir div dl dt 
        em
        fieldset font form frame frameset 
        h1 h2 h3 h4 h5 h6 head hr html 
        i iframe img input ins isindex 
        kbd 
        label legend li link 
        map menu meta 
        noframes noscript
        object ol optgroup option 
        p param pre 
        q 
        s samp script select small span strike strong style sub sup 
        table tbody td textarea tfoot th thead title tr tt 
        u ul
        var
    );


#class->generate_html_commands(
#    elements()
#);


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;
    my ($end_paren, @classes, $class, $id);

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # skip over the keyword (but *not* whitespace) and look for any attributes
    # enclosed in [...] or (...)
    $$token->next($token);
    
    if ($end_paren = $$token->in(ATTR_PARENS, $token)) {
        # parse expressions.  Any precedence (0), allow empty lists (1)
        $self->[ARGS] = $$token->parse_block($token, $scope, 0, 1)
            || return $self->missing_error( expressions => $token );
    
        # check the next token matches the closing bracket
        return $self->missing_error( $end_paren, $token)
            unless $$token->is( $end_paren, $token );
    }
    
    # look for dotted class names, e.g. 'a.menu' is syntactic sugar for 
    # 'a[class="menu"]'
    while ($$token->is(CLASS_DOT, $token)) {
        $class = $$token->parse_word($token, $scope)
            || return $self->missing_error( word => $token );
        push(@classes, $class->text);           # FIXME: no context
    }
    if (@classes) {
        $class = join(' ', @classes);
    }

    # look for #ident, e.g. 'a#home' is sugar for 'a[id="home"]'
    if ($$token->is(ID_HASH, $token)) {
        $id = $$token->parse_word($token, $scope)
            || return $self->missing_error( word => $token );
        $id = $id->text;                        # FIXME - no context
    }

    # stuff extra class/id info into EXPR.
    if (defined $class || defined $id) {
        $self->[EXPR] = {
#            defined $id    ? (id    => $id)    : (),
#            defined $class ? (class => $class) : ()
            id    => $id,
            class => $class,
        }
    }

    # skip any whitespace, then parse the following block
    $self->[BLOCK] = $$token
        ->skip_ws($token)
        ->parse_body($token, $scope, $self)
        || return $self->missing_error( $self->ARG_BLOCK => $token );

    $self->debug("got block for $self->[TOKEN]") if DEBUG;
        
    return $self;
}


sub element_name_hash {
    \%ELEMENT_NAMES;
}


sub element_names {
    return wantarray
        ?  keys %ELEMENT_NAMES
        : [keys %ELEMENT_NAMES];
}


sub elements {
    my @elems = 
        map { $_ => element($_) }
        keys %ELEMENT_NAMES;
        
    return wantarray
        ?  @elems
        : \@elems;
}


sub element {
    my $name = shift;

    return sub {
        my $self  = shift;
        my $info  = $self->[EXPR];       # dotted class names / ident
        my $args  = $self->[ARGS];       # regular attrs
        my $attrs = '';
        my $hash;

        # look to see if we've got an attributes expression and/or any 
        # extra .class names or #id specified
        if ($args || $info) {
            # evaluate the attrs expression to get a hash ref or use a blank
            $hash = { $args ? $args->pairs(@_) : () };

            if (DEBUG) {
                $self->debug("attr: ", $self->dump_data($hash));
                $self->debug("info: ", $self->dump_data($info));
            }
            
            if ($info) {
                # merge in any extra classes
                $hash->{ class } = join(
                    SPACE,
                    grep { defined($_) && length($_) }
                    $hash->{ class },
                    $info->{ class },
                );
                delete $hash->{ class }
                    unless defined $hash->{ class } && length $hash->{ class };

                if (defined $hash->{ id } && length $hash->{ id }) {
                    # check we don't have id specified twice
                    return $self->error_msg( dup_id => $self->[TOKEN], $hash->{ id }, $info->{ id } )
                        if defined $info->{ id } && length $info->{ id };
                }
                else {
                    $hash->{ id } = $info->{ id }
                        if defined $info->{ id } && length $info->{ id };
                }
            }
            
            $attrs = hash_html_attrs($hash);
        }
        
        return '<' . $name . $attrs . '>'
             . $self->[BLOCK]->text(@_) 
             . '</' . $name . '>';
    };
}


sub commands {
    my ($self, $params) = self_params(@_);
    my @cmds;
    
    # load everything by default
    $params = \%ELEMENT_NAMES
        unless %$params;

    $self->debug("creating HTML commands: ", $self->dump_data($params)) if DEBUG;
    
    while (my ($alias, $name) = each %$params) {
        class->generate_html_commands( $name => element($name) )
            unless $ELEMENT_COMMANDS{ $name }++;
        
        push(@cmds, [ $alias, sprintf(HTML_ELEMENT, $name), (CMD_PRECEDENCE) x 2 ]);
    }
    
    $self->debug("created commands: ", $self->dump_data(\@cmds)) if DEBUG;
    
#    my @cmds = 
#        map { [ $_, sprintf(HTML_ELEMENT, $_), (CMD_PRECEDENCE) x 2 ] }
#        keys %ELEMENT_NAMES;
    
    return \@cmds;
    
    return wantarray
        ?  @cmds
        : \@cmds;
}


1;