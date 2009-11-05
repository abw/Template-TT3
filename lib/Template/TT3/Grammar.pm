package Template::TT3::Grammar;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Elements',
    constants => 'HASH ARRAY REGEX',
    import    => 'class',
    accessors => 'keywords nonwords',
    patterns  => '$IDENT',
    constant  => {
        TOKEN   => 0,
        ELEMENT => 1,
        LPREC   => 2,
        RPREC   => 3,
    },
    messages  => {
        symbol_dup  => "Duplicate '%s' symbol found in rules for '%s' and '%s' elements",
        element_dup => "Duplicate '%s' element found in rules for '%s' and '%s' symbols",
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
        if ($token =~ /\W/) {
            $self->debug("nonword: $token") if DEBUG;
            $nonwords->{ $token } = $symbol;
        }
        else {
            $self->debug("keyword: $token") if DEBUG;
            $keywords->{ $token } = $symbol;
        }
    }
    
    # any cached regex built from symbol table is invalid now
    delete $self->{ nonword_regex };
    
    return $symbols;
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


sub match_keyword {
    my ($self, $input, $output, $pos) = @_;
    $pos ||= pos $$input;
    
    if ($$input =~ /$IDENT/cog) {
        # we'll cut out the middle man in the interests of speed
        return $output->token( 
            ( $self->{ constructor }->{ $1 } || $self->constructor($1) )
                ->($1, $pos) 
        );
        # otherwise a call like this would do the trick, at the cost of 
        # 2 additional methods calls:
        #   return $self->matched($input, $output, $pos, $1);
    }
}


sub match_nonword {
    my ($self, $input, $output, $pos) = @_;
    $pos ||= pos $$input;
    
    if ($$input =~ /$self->{ nonword_regex }/cg) {
        return $output->token( 
            ( $self->{ constructors }->{ $1 } || $self->constructor($1) )
                ->($1, $pos) 
        );
    }
}


sub matched {
    my ($self, $input, $output, $pos, $token) = @_;

    return $output->token( 
        ( $self->{ constructor }->{ $token } || $self->constructor($token) )
            ->($token, $pos) 
    );
}


sub constructor {
    my $self  = shift;
    my $token = shift;
    
    # NOTE: we should be able to shortcut the constructor function if instead 
    # we store the $class returned by $self->element_class() somewhere along 
    # with the $meta data returned by $class->init_meta().  Then we can cut 
    # out another middle-man method in match_keyword() and match_nonword() by 
    # performing a direct: bless [$meta, $token, $pos], $class;
    
    return $self->{ constructors }->{ $token } ||= do {
        my $symbol = $self->{ symbols }->{ $token }
            || return $self->error_msg( invalid => symbol => $token );
        my $config = {
            elements => $self,
            lprec    => $symbol->[LPREC],
            rprec    => $symbol->[RPREC],
        };
        $self->element_class($symbol->[ELEMENT])
             ->constructor($config);
    }
}

1;

__END__    
