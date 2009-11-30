package Template::TT3::Tag;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
#   throws    => 'tt3.tag',
    utils     => 'blessed params',
    patterns  => ':all',
    dumps     => 'start end style',
    accessors => 'start end style grammar',
    constants => 'HASH ARRAY REGEX NONE OFF ON BLANK CMD_PRECEDENCE :elements',
    constant  => {
        GRAMMAR   => 'Template::TT3::Grammar::TT3',
		BACKSLASH => '\\',
    },
    messages  => {
        bad_style  => 'Invalid tag style specified: %s',
        no_token   => 'No token specified for %s of tag.',
        no_end     => 'Missing end token for tag: %s',
        unexpected => 'Unexpected token: %s',
    };
 
our $TAG_STYLES     = { };
our $STYLE_PATTERNS = { };
our $SQUOTE_ESCAPES = {
	(BACKSLASH) x 2
};
our $DQUOTE_ESCAPES = {
    n    => "\n",
    t    => "\t",
	(BACKSLASH) x 2
};


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
        #        NOT_elsif (ref $style eq REGEX) {
        #            # style can be a regular expression for the start tag and we 
        #            # re-use the end tag (no, I think this is a bad idea)
        #            ($start, $end) = ($style, $self->{ end });
        #            $style = undef;
        #        }
        elsif ($style eq OFF) {
            $self->debug("turned tag off") if DEBUG;
            $self->{ off } = 1;
            ($style, $start, $end) = @$self{ qw( style start end ) };
#            $self->debug("TURNED OFF ($style, $start, $end)");
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
    
    # TODO: we need a special case for outline tags that have the newline
    # as the end of tag
    
    if (defined $end) {
        $end = ref $end eq REGEX ? $end : quotemeta($end);
        $eol = qr/
            [^\n]*?        # capture everything on this line non-greedily
                           # TODO: fix this so that outline tags work - they
                           # have a "\n" end tag that should be matched before
                           # the newline
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
    my $comment = qr/ (?: ^\s*|\s+ ) \# $eol /msx;

    # whitespace can contain ignorable comments
    # TODO: fix this so that we don't gobble a newline that an outline 
    # token may be expecting
    my $wspace = qr/ (?:$comment|\s+)+ /sx;

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

    # TODO: change this to use Template::Grammars so we get clean name
    # translation
    $grammar = class($grammar)->load->instance($config)
        unless blessed $grammar;
    
    $self->{ grammar  } = $grammar;
    $self->{ keywords } = $grammar->keywords;
    $self->{ nonwords } = $grammar->nonwords;
    $self->{ match_nw } = $grammar->nonword_regex;

    return $self;
}


# TODO: rename this to change_tags() or something more descriptive

sub change {
    shift->init_tag({ style => shift });    # NOTE: init_tag() expect hash ref
}


sub reset {
    my $self    = shift;
    my $grammar = $self->{ grammar };

    # call init_tag() to reset the tag start/end tokens
#    $self->debug("reseting tag");
    $self->{ off } = 0;
    $self->init_tag;
#    $self->debug("reset tag: ", $self->dump);
    
    # reload the original keywords 
    $self->{ keywords } = $grammar->keywords
        if delete $self->{ dirty_keywords };
}


sub keywords {
    my $self     = shift;
    my $keywords = $self->{ keywords };
    
    # For efficiency we share a copy of the keyword with the grammar.  But if 
    # anyone tries to update the keywords (which might include us passing
    # out a reference to them) then we need to clone them first so that we
    # don't affect the original keyword set defined in the grammar.  We only 
    # ever need to clone them once so we use the dirty_keywords flags to keep
    # track of when we've done that.

    # hmmm... come to think of it... that's not going to work....  we have
    # to modify the grammar's copy of the keywords so the grammar can 
    # generate elements for them... see commands()
#    $keywords = $self->{ keywords } = { %$keywords }
#        unless $self->{ dirty_keywords };
    
    if (@_) {
        my $extra = params(@_);
        @$keywords{ keys %$extra } = map {
            [ $_, 'cmd_' . $_, CMD_PRECEDENCE, CMD_PRECEDENCE ]
        } values %$extra;
        $self->debug("augmented keywords: ", $self->dump_data($keywords));
    }

    return $keywords;
}


sub commands {
    # FIXME: this messes up the grammar
    my $self = shift;
    $self->{ keywords } = $self->{ grammar }->commands(@_);
    $self->debug("new keywords: ", $self->dump_data($self->{ keywords }))
        if DEBUG;
}


sub add_commands {
    my $self = shift;
    $self->{ keywords } = $self->{ grammar }->add_commands(@_);
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
    return $self->tokenise($input, $output, $scope);
}
    
        
sub tokenise {
    my ($self, $input, $output, $scope) = @_;
    my $pos = pos $$input;
    my $type;

    while (1) {
        $self->debug("SCAN \@$pos: ", $self->remaining_text($input)) if DEBUG;
        
        # TODO: consider generating the tokens in here and calling
        # $output->token($token)

        if ($$input =~ /$NAMESPACE/cog) {
            $self->namespace_token($input, $output, $scope, $1, $pos);
        }
        elsif ($$input =~ /$IDENT/cog) {
            if ($type = $self->{ keywords }->{ $1 }) {
                $self->debug("matched keyword: [$1]") if DEBUG;
                $self->{ grammar }->matched($input, $output, $1, $pos);
                # TMP HACK
                # $output->keyword_token($1, $pos);
                # TODO:
                # $type = "${type}_token";
                # $output->$type($1, $pos);
            }
            else {
                $self->debug("matched word: [$1]") if DEBUG;
                $output->word_token($1, $pos);
            }
        }
        elsif ($$input =~ /$SQUOTE/cog) {
            $self->debug("matched single quote: [$1] [$2]") if DEBUG;
            my ($token, $content) = ($1, $2);
            $content =~ s/\\(['\\])/$1/ge;
            $output->squote_token($token, $pos, $content);
        }
        elsif ($$input =~ /$DQUOTE/cog) {
            $self->debug("matched double quote: $1") if DEBUG;
            $self->tokenise_string($input, $output, $scope, $1, $pos, $2, '"');
#            $output->dquote_token($1, $pos, $2);
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
            $self->debug("matched nonword: $1") if DEBUG;
            $self->{ grammar }->matched($input, $output, $1, $pos);
        }
        elsif ($$input =~ /$NUMBER/cog) {
            $self->debug("matched number: $1") if DEBUG;
            $output->number_token($1, $pos);
        }
        elsif ($$input =~ /$self->{ match_whitespace }/cg) {
            $self->debug("matched whitespace: $1") if DEBUG;
            $output->whitespace_token($1, $pos);
        }
        else {
            return $self->unexpected($input);
        }
        
        $pos = pos $$input;
    }

    return 0;
}


sub tokenise_string {
    my ($self, $input, $output, $scope, $token, $pos, $content, $delim) = @_;
    # phew! what a lot of arguments

    $self->debug(
        "tokenise_string(\n",
        "  input: $input\n",
        " output: $output\n",
        "  scope: $scope\n",
        "  token: $token\n",
        "content: $content\n",
        "  delim: $delim\n"
    ) if DEBUG;
    
    my $dquote = $output->dquote_token($token, $pos);
    my (@text, $tpos, $branch);
    my $n = 0;
    $pos += length $delim;
    
    $self->debug("created dquote string token: $dquote") if DEBUG;
    
    while ($content =~ /$DQUOTE_CHUNK/cogx) {
        if (defined $1) {
            # Plain text gets pushed into the @text buffer.  If it's the 
            # first text chunk then we save the start position in $tpos.
            # Then we increment our running $pos count by the number of 
            # text characters we've consumed.
            $tpos = $pos unless @text;
            push(@text, $1);
            $pos += length $1;
            $self->debug("double quoted text: $1") if DEBUG;
        }
        elsif (defined $2) {
            # An escaped character is either an escape sequence like \n or \t
            # that is substituted for its literal text, or it's protecting the 
            # next character, e.g. \" \$ \".  Either way, it's static text so
            # it gets pushed onto the buffer as above.
            $tpos = $pos unless @text;
            push(@text, 
					$DQUOTE_ESCAPES->{ $2 } 		# \n \t \\
	 			||  ($2 eq $delim && $delim)        # \"
	 			||  BACKSLASH . $2                  # \anything else
			);
            $pos += 1 + length $2;      # Is this always 1?  What about utf8?
            $self->debug("double quoted escape: $2 => $text[-1]") if DEBUG;
        }
        elsif (defined $3) {
            # A $word is tokenised as a variable.  If we've got any preceding
            # text in the @text buffer then we need to compact it into a 
            # single text string which gets added as a text element to the 
            # end of the branch, or at the start of a new branch if we haven't
            # created a branch element yet.
            $self->debug("double quoted variable: [$3]") if DEBUG;
            if (@text) {
                $branch = $branch 
                    ? $branch->append( text => join(BLANK, @text), $tpos )
                    : $dquote->branch( text => join(BLANK, @text), $tpos );
                @text = ();
            }
            $pos++;     # account for leading '$'
            $branch = $branch
                ? $branch->append( word => $3, $pos )
                : $dquote->branch( word => $3, $pos );

            $pos += length $3;
            
            # look for any dotops
            while ($content =~ /$DOT_WORD/cogx) {
                $self->debug("double quoted dotop: [$1]") if DEBUG;
                $branch = $branch
                    ->append( op_dot => '.', $pos++ )
                    ->append( word   => $1, $pos );
                $pos += length $1;
            }
        }
        else {
            return $self->error("tokenise_string() failed to match anything");
        }
 
# for debugging runaways       
#        unless (++$n % 10) {
#            $self->debug("PAUSING....");
#            sleep 1;
#        }
    }

    if (@text) {
        if ($branch) {
            # if we've got a branch then we add any trailing text to it
            $branch = $branch->append( text => join(BLANK, @text), $tpos );
        }
        else {
            # if we haven't got a branch then we've just got static text,
            # in which case we don't need a branch at all
            $dquote->[EXPR] = join(BLANK, @text);
        }
    }
    
    # if we created a branch then add a terminating EOF token
    $branch->append('eof')
        if $branch;

    return $dquote;
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


sub remaining_text {
    my ($self, $text) = @_;
    my $pos    = pos $$text;
    my $result = $self->match_to_end($text);
    pos $$text = $pos;
    return $result || '';
}


#-----------------------------------------------------------------------
# error handling
#-----------------------------------------------------------------------

sub unexpected {
    my ($self, $text) = @_;
    my $remain = $text->lookahead(32, '...');  $remain =~ s/\n.*//s;
    my $where  = $text->whereabouts;
    my $msg    = $self->message( unexpected => $remain );

    return $self->raise_error(
        syntax => %$where,
        info   => $msg,
    );
}

1;

__END__

=pod

=head1 METHODS

=head2 sub tokenise_string($input, $output, $scope, $token, $pos, $content, $delim)


This method takes a quoted string like "foo $bar" and tokenises it into chunks
of text and variable references. 

NOTE: The argument list is something of a monstrosity which is likely to get
pared down Real Soon Now.

The first three arguments are the regular $input, $output and $scope. Then we
have the complete $token including any quote marks. We create a literal dquote
element to represent this complete token in case we need to regenerate the
original source code. The next argument, $pos, tells us the source position it
was parsed at. That goes into the token element too. The next argument is the
string content without the enclosing quotes. The final argument is the
delimiter, usually '"', but it can be something else, e.g. in the case of
qq:/foo $bar/. 

We tokenise the string and create a sub-stream of tokens representing the
original chunks. We don't want to inject these into the normal output stream
because it would then look like they were read from the source, messing up any
regeneration. So we hang them off the $token->[BRANCH] pointer.

    +-------------------+  BRANCH   +-------------+
    | dquote:"foo $bar" |---------->| text:"foo " |
    +-------------------+           +-------------+
              |                            |  NEXT
             \|/                          \|/
             TBA                    +--------------+
                                    | word:bar     |
                                    +--------------+

