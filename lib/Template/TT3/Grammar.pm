package Template::TT3::Grammar;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Elements',
    constants => 'HASH ARRAY REGEX CMD_PRECEDENCE CMD_ELEMENT DELIMITER',
    import    => 'class',
    accessors => 'keywords nonwords',
    patterns  => '$IDENT',
    constant  => {
        TOKEN    => 0,
        ELEMENT  => 1,
        LPREC    => 2,
        RPREC    => 3,
    },
    messages  => {
        symbol_dup  => "Duplicate '%s' symbol found in rules for '%s' and '%s' elements",
        element_dup => "Duplicate '%s' element found in rules for '%s' and '%s' symbols",
    };

use constant {
    is_keyword => qr/^$IDENT$/
};


#*init = \&init_grammar;


sub init {
    my ($self, $config) = @_;
    $self->init_elements($config);
    $self->init_grammar($config);
    return $self;
}


sub init_grammar {
    my ($self, $config) = @_;
    my $class = $self->class;

    $self->init_factory($config);
    
    $self->{ keywords } = $class->hash_vars( 
        KEYWORDS => $config->{ keywords }
    );

    $self->{ nonwords } = $class->hash_vars( 
        NONWORDS => $config->{ nonwords }
    );

    $self->symbols( 
        $class->list_vars( 
            SYMBOLS => $config->{ symbols } 
        )
    );

    $self->commands( 
        $class->list_vars( 
            COMMANDS => $config->{ commands } 
        )
    );

    return $self;
}


sub symbols {
    my $self     = shift;
    my $symbols  = $self->{ symbols } ||= { }; return $symbols unless @_;
    my $args     = @_ == 1 && ref $_[0] eq ARRAY ? shift : [ @_ ];
    my $nonwords = $self->{ nonwords };
    my $keywords = $self->{ keywords };
    my $names    = $self->{ element_names };
    my ($symbol, $token, $name, $lprec, $rprec, $existing);

    $self->debug("adding symbols: ", $self->dump_data($args), "\n") if DEBUG;

    # we need to be able to unshift symbols onto the start of the list, so
    # a simple foreach won't do here.
    my @symbols = @$args;

    while (@symbols) {
        # grab the next symbol
        $symbol = shift @symbols;

        # upgrade token to list ref if it's just a name
        $symbol = [ $symbol, 0, 0 ] unless ref $symbol eq ARRAY;
        ($token, $name, $lprec, $rprec) = @$symbol;

        # if the token is an array ref then we duplicate the entire entry for
        # each token in @$token, pushing them back onto the start of @symbols
        if (ref $token eq ARRAY) {
            unshift(
                @symbols,
                map { my @clone = @$symbol; $clone[TOKEN] = $_; \@clone } 
                @$token
            );
            redo;
        }
    
        # check we haven't got an existing entry for a symbol
        if ($symbols->{ $token }) {
            return $self->error_msg( 
                symbol_dup => $token, $symbols->{ $token }->[ELEMENT], $name 
            );
        }

        # stash the symbol away by both token and element name
        $names->{ $name } = $symbol;
        $symbols->{ $token } = $symbol;

        # words go in keywords, non-words go in nonwords
        if ($token =~ /^$IDENT$/) { #is_keyword) {
            $self->debug("keyword: $token") if DEBUG;
            $keywords->{ $token } = $symbol;
        }
        else {
            $self->debug("nonword: $token") if DEBUG;
            $nonwords->{ $token } = $symbol;
        }
    }
    
    # any cached regex built from symbol table is invalid now
    delete $self->{ nonword_regex };
    
    return $symbols;
}


sub commands {
    my $self     = shift;
    my $args     = @_ == 1 && ref $_[0] eq ARRAY ? shift : [ @_ ];
    my $symbols  = $self->{ symbols };
    my $keywords = $self->{ keywords };
    my $names    = $self->{ element_names };
    my (@commands, $command, $name, $element, $lprec, $rprec);

    $self->debug("adding commands: ", $self->dump_data($args), "\n") if DEBUG;

    @commands = map { 
        ref $_ eq ARRAY ? $_ : split(DELIMITER, $_) 
    } @$args;

    foreach $command (@commands) {
        if (ref $command eq ARRAY) {
            ($name, $element, $lprec, $rprec) = @$command;
        }
        else {
            $name    = $command;
            $element = sprintf(CMD_ELEMENT, $command);
            $lprec   = $rprec = CMD_PRECEDENCE;
            $command = [$name, $element, $lprec, 0];
        }
        
        # check we haven't got an existing entry for a keyword
        if ($symbols->{ $name }) {
            return $self->error_msg( 
                symbol_dup => $name, $symbols->{ $name }->[ELEMENT], $name 
            );
        }

        # stash the symbol away by both token and element name
        $names->{ $name     } = $command;
        $symbols->{ $name   } = $command;
        $keywords->{ $name  } = $command;

        $self->debug("added command $name => ", $self->dump_data($command))
            if DEBUG;
    }
    
    return $keywords;
}


sub nonword_regex {
    my $self = shift;

    return $self->{ nonword_regex } ||= do {
        my (@single, @multiple, @regex, $regex);

        # construct a regex to match all start symbols 
        foreach my $token (keys %{ $self->{ nonwords } }) {
            # partition all symbols into single/multi character tokens 
            if (ref $token eq REGEX) {
                push(@regex, $token);
            }
            elsif (length $token == 1) {
                push(@single, quotemeta $token);
            }
            else {
                push(@multiple, quotemeta $token);
            }
        }

        # sort multi-character symbols according to length, longest first.
        # these get their own alternation rules: <=|=>|==|[+\-\*]
        @multiple = sort { length $b <=> length $a } @multiple;

        # add any regex matches
        push(@multiple, @regex);
    
        # single character operators can be put in a character class: [\!\-\+]
        push(@multiple, '[' . join('', @single) . ']') if @single;

        # glue it all together
        $regex = join('|', @multiple);
        
        $self->debug("initialised symbol matching regex: / \\G $regex /\n") if DEBUG;
        
        qr/ \G ($regex)/sx;
    };
}


sub match_nonword {
    my ($self, $input, $output, $pos) = @_;
    $pos ||= pos $$input;

    $self->matched($input, $output, $1, $pos)
        if $$input =~ /$self->{ nonword_regex }/cg;
}


sub match_keyword {
    my ($self, $input, $output, $pos) = @_;
    $pos ||= pos $$input;
    
    $self->matched($input, $output, $1, $pos)
        if $$input =~ /$IDENT/cog;
}


sub matched {
    my ($self, $input, $output, $token, $pos) = @_;

    return $output->token( 
        ( $self->{ token_constructor }->{ $token } 
       || $self->token_constructor($token) )
            ->($token, $pos) 
    );
}


sub token_constructor {
    my $self  = shift;
    my $token = shift;
    
    # NOTE: we should be able to shortcut the constructor function if instead 
    # we store the $class returned by $self->element_class() somewhere along 
    # with the $meta data returned by $class->init_meta().  Then we can cut 
    # out another middle-man method in match_keyword() and match_nonword() by 
    # performing a direct: bless [$meta, $token, $pos], $class;
    
    # TODO: this is kinda broken.  We end up with conflicts between a keyword
    # called 'block' and an element called 'block'
    return $self->{ token_constructor }->{ $token } ||= do {
        my ($symbol, $element, $config);

        if ($symbol = $self->{ symbols }->{ $token }) {
            $config = {
                elements => $self,
                lprec    => $symbol->[LPREC],
                rprec    => $symbol->[RPREC],
            };
            $element = $symbol->[ELEMENT];
        }
        else {
            return $self->error_msg( invalid => symbol => $token );
        }
        $self->element_class($element)
             ->constructor($config);
    };
}


1;

__END__    
