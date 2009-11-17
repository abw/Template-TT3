package Template::TT3::Tag;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
#   throws    => 'tag',
    utils     => 'blessed',
    patterns  => ':all',
    dumps     => 'start end style',
    accessors => 'start end style',
    constants => 'HASH ARRAY REGEX NONE OFF ON',
    constant  => {
        GRAMMAR => 'Template::TT3::Grammar::TT3',
    },
    messages  => {
        bad_style  => 'Invalid tag style specified: %s',
        no_token   => 'No token specified for %s of tag.',
        no_end     => 'Missing end token for tag: %s',
    };
 
our $TAG_STYLES     = { };
our $STYLE_PATTERNS = { };


#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------

sub init {
    my $self   = shift;
    my $config = shift || $self->{ config };
    
    $self->init_tag($config);
    $self->init_grammar($config);
    
    $self->{ config } ||= $config;
    
    return $self;
}


sub init_tag {
    my $self   = shift;
    my $config = shift || $self->{ config };
#    $self->debug("init_tag() with ", $self->dump_data($config));
    my $style  = $config->{ tag_style } || $config->{ style };
    my $start  = $config->{ tag_start } || $config->{ start };
    my $end    = $config->{ tag_end   } || $config->{ end   };

    if (defined $style) {
        if (ref $style eq HASH) {
            # style can be an array ref of [start, end], e.g. ['[%', '%]']
            ($start, $end) = @$style{ qw( start end ) };
            $style = undef;
        }
        elsif (ref $style eq ARRAY) {
            # style can be an array ref of [start, end], e.g. ['[%', '%]']
            ($start, $end) = @$style;
            $style = undef;
        }
#        elsif (ref $style eq REGEX) {
#            # style can be a regular expression for the start tag and we 
#            # re-use the end tag (no, I think this is a bad idea)
#            ($start, $end) = ($style, $self->{ end });
#            $style = undef;
#        }
        elsif ($style eq OFF) {
            $self->debug("turned tag off") if DEBUG;
            $self->{ off } = 1;
            ($style, $start, $end) = @$self{ qw( style start end ) };
        }
        elsif ($style eq ON) {
            $self->debug("turned tag on") if DEBUG;
            $self->{ off } = 0;
            ($style, $start, $end) = @$self{ qw( style start end ) };
        }
        elsif ($style =~ /^\s*(\S+)\s+(\S+)\s*$/) {
            # ...or a string containing "start end", e.g. '[% %]'
            ($start, $end) = ($1, $2);
            $style = undef;
        }
        else {
            # ...or a string containing a style name defined in $TAG_STYLES
            # NOTE: can't accommodate tag_styles defined in config
            my $tokens = $self->class->hash_value( TAG_STYLES => $style )
                || return $self->error_msg( bad_style => $style );
            ($start, $end) = @$tokens;
        }
    }

    # If we don't have a style name (either because one wasn't specified, or
    # it referenced a hash/list/string that we expanded above) then we create 
    # a canonical identifier for the tag_style based on start/end combination 
    # (e.g. '[% %]') or 'none' if the tag_start and tag_end are undefined 
    # (in case we're parsing "naked" TT code which isn't embedded in tags).
    # We do this via a method so that subclasses can further tweak the 
    # definitive style and start/end tokens.
    $self->{ start } = $start;      # save these for accessors to use
    $self->{ end   } = $end;

    ($style, $start, $end) = $self->init_tag_style($style, $start, $end);

    $self->{ style     } = $style;  # save the modified versions for real
    $self->{ tag_start } = $start;
    $self->{ tag_end   } = $end;

    # construct regex patterns for this tag style and cache for next time
    my $patterns = $STYLE_PATTERNS->{ $style } ||= do {
        $self->debug("Compiling regexen for tag parser style: $style\n") if DEBUG;
        $self->init_patterns($start, $end);
    };

    # import patterns into $self with a match_prefix, e.g. match_whitespace
    @$self{ 
        map { "match_$_" } 
        keys %$patterns 
    } = values %$patterns;
    
    return $self;
}


sub init_tag_style {
    my ($self, $style, $start, $end) = @_;

    $style ||= ( defined($start) || defined($end) )
               ? join(' ', map { defined $_ ? $_ : '' } $start, $end)
               : NONE;
    
    return ($style, $start, $end);
}


sub init_patterns {
    my ($self, $start, $end) = @_;
    my $eol;

    # We compile a set of regexen to identify the various language tokens 
    # which depend on the tag start and/or end.  This includes things like 
    # comments (which continue to to the end of line or the end of tag), 
    # whitespace (which can include comments), and various operators which 
    # can have whitespace preceeding them.  This set of regexen in cached
    # in the $STYLE_PATTERNS package variable for subsequent parser instances 
    # to use.

    # define a regex to match to the end of the tag if tag_end is 
    # defined or to the end of line (\n) or end of file if not
    if (defined $end) {
        $end = ref $end eq REGEX ? $end : quotemeta($end);
        $eol = qr/
            [^\n]*?        # capture everything on this line non-greedily
            (?: \n         # either match and consumer a newline character
              | (?=        # or look ahead for the end of the text or the        
                 $end      # end-of-tag marker
              )
            ) 
        /sx;
    }
    else {
        $eol = qr/
             [^\n]*        # anything up to end of line
            (?:\n|$)       # end of line or end of file
        /x;
    };
    
    # comments start '#' and extend to the end of line (or end of tag)
    my $comment = qr/ \# $eol /sx;

    # whitespace can contain ignorable comments
    my $wspace = qr/ (?:\s+|$comment)+ /sx;

    # now construct table of regexen for matching various operators and 
    # other tokens, accounting for any whitespace/comments surrounding
    my $patterns = {
        nothing      => qr/ \G /x,
        to_eol       => qr/ \G ($eol) /x,
        whitespace   => qr/ \G ($wspace) /sx,
    };

    # add regexen for matching end of tag and everything up to the tag end
    if (defined $end) {
        $patterns->{ at_end } = qr/ \G ($end) /sx;
        $patterns->{ to_end } = qr/ \G (.*?) ($end) /sx;
    }
    else {
        $patterns->{ at_end } = qr/ \G \z /sx;
        $patterns->{ to_end } = qr/ \G (.*) \z /sx;
    }

    return $patterns;
}


sub tag_map {
    my $self    = shift;
    my $start   = $self->{ tag_start };
    my $tag_map = shift || {
        start  => [ ],    # list of all start tokens
        regex  => [ ],    # list of regex-based start tokens and tags
        fixed  => { },    # hash mapping fixed start tokens to tags
    };

#    $self->debug("tag_map $self is ", $self->{ off } ? 'OFF' : 'ON');
    
    return $tag_map if $self->{ off };

    if (ref $start eq REGEX) {
        # tags that start with a regex get added to a list for sequential matching
        $self->debug("tag start is a regex: $start\n") if DEBUG;
        push(@{ $tag_map->{ regex } ||= [] }, [ $start, $self ]);
    }
    else {
        # those that have a fixed start token get added to lookup hash for direct matching
        $self->debug("tag start is fixed: $start\n") if DEBUG;
        $tag_map->{ fixed }->{ $start } = $self;
    }

    # add start token/regex to list of all start tokens to match
    push(@{ $tag_map->{ start } ||= [] }, $start);

    return $tag_map;
}


sub init_grammar {
    my $self    = shift;
    my $config  = shift || $self->{ config };
    my $grammar = $config->{ grammar } 
               || $self->class->any_var('GRAMMAR')
               || $self->GRAMMAR;
    
    $grammar = $grammar->new($config)
        unless blessed $grammar;
    
    $self->{ grammar  } = $grammar;
    $self->{ keywords } = $grammar->keywords;
    $self->{ nonwords } = $grammar->nonwords;
    $self->{ match_nw } = $grammar->nonword_regex;

    return $self;
}


sub change {
    shift->init_tag({ style => shift });    # NOTE: init_tag() expect hash ref
}


sub reset {
    shift->init_tag;                        # no args - uses $self->{ config };
}


#-----------------------------------------------------------------------
# Scanning methods
#-----------------------------------------------------------------------

sub scan {
    my ($self, $input, $output, $scope, $text, $start, $pos) = @_;

    # push any preceding text onto the token list
    $self->debug("pre-text: <$text>") if DEBUG && $text;
    $output->text_token($text, $pos)
        if defined $text && length $text;
    
    # push the tag start token onto the token list
    $self->debug("tag starting: <$start>") if DEBUG && $start;
    $pos = pos $$input;

    $output->tag_start_token($start, $pos - length($start))
        if defined $start && length $start;
    
    # call the main tokenising method
    return $self->tokens($input, $output, $scope);
}
    
        
sub tokens {
    my ($self, $input, $output, $scope) = @_;
    my $pos = pos $$input;
    my $type;

    while (1) {
        $self->debug("SCAN \@$pos: ", $self->peek_to_end($input)) if DEBUG;
        
        # TODO: consider generating the tokens in here and calling
        # $output->token($token)

        if ($$input =~ /$NAMESPACE/cog) {
            $self->namespace_token($input, $output, $scope, $1, $pos);
        }
        elsif ($$input =~ /$IDENT/cog) {
            if ($type = $self->{ keywords }->{ $1 }) {
                $self->{ grammar }->matched($input, $output, $1, $pos);
                # TMP HACK
                # $output->keyword_token($1, $pos);
                # TODO:
                # $type = "${type}_token";
                # $output->$type($1, $pos);
            }
            else {
                $output->word_token($1, $pos);
            }
        }
        elsif ($$input =~ /$SQUOTE/cog) {
            $self->debug("matched single quote: $1") if DEBUG;
            $output->squote_token($1, $pos);
        }
        elsif ($$input =~ /$DQUOTE/cog) {
            $self->debug("matched double quote: $1") if DEBUG;
            $output->dquote_token($1, $pos);
        }
        elsif ($$input =~ /$self->{ match_at_end }/cg) {
            $self->debug("matched end of tag: $1") if DEBUG;

            # add the tag end token and return it to scan() so it can 
            # identify any post-chomping flags
            $output->tag_end_token($1, $pos) 
                if  defined $1 && length $1;
                
            return $1;
        }
        elsif ($$input =~ /$self->{ match_nw }/cg) {
            $self->{ grammar }->matched($input, $output, $1, $pos);
        }
        elsif ($$input =~ /$NUMBER/cog) {
            $self->debug("matched number: $1") if DEBUG;
            $output->number_token($1, $pos);
        }
        elsif ($$input =~ /$self->{ match_whitespace }/cg) {
            $output->whitespace_token($1, $pos);
        }
        else {
            return $self->error("Unexpected input: [", $self->peek_to_end($input), "]");
        }
        
        $pos = pos $$input;
    }

    return 0;
}



#-----------------------------------------------------------------------
# Token matching methods
#-----------------------------------------------------------------------

sub match_whitespace {
    my ($self, $text) = @_;

    # skip whitespace and ignorable comments
    return $$text =~ /$self->{ match_whitespace }/cg
        ? $1 
        : undef;
}


sub match_to_end {
    my ($self, $text) = @_;
    return $1 if $$text =~ /$self->{ match_to_end }/gc;
}


sub match_to_eol {
    my ($self, $text) = @_;
    return $1 if $$text =~ /$self->{ match_to_eol }/gc;
}


sub match_to_eof {
    my ($self, $text) = @_;
    return $1 if $$text =~ / \G (.*) $ /gcsx;
}


sub peek_to_end {
    my ($self, $text) = @_;
    my $pos    = pos $$text;
    my $result = $self->match_to_end($text);
    pos $$text = $pos;
    return $result || '';
}


1;

