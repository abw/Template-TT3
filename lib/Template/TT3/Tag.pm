package Template::TT3::Tag;

use Template::TT3::Grammar::TT3;
use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
#   throws    => 'tag',
    utils     => 'blessed',
    patterns  => ':all',
    constants => 'HASH ARRAY REGEX NONE',
    constant  => {
        GRAMMAR => 'Template::TT3::Grammar::TT3',
    },
    messages  => {
        bad_style  => 'Invalid tag style specified: %s',
        no_token   => 'No token specified for %s of tag.',
    };
 
our $TAG_STYLES     = { };
our $STYLE_PATTERNS = { };
   

*init = \&init_tag;


sub init_tag {
    my $self   = shift;
    my $config = shift || $self->{ config };
    $self->init_tag_style($config);
    $self->init_grammar($config);
    return $self;
}


sub init_tag_style {
    my $self   = shift;
    my $config = shift || $self->{ config };
    my $style  = $config->{ tag_style } || $config->{ style };
    my $start  = $config->{ tag_start } || $config->{ start };
    my $end    = $config->{ tag_end   } || $config->{ end   };

    if ($style) {
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
    $style ||= ( defined($start) || defined($end) )
               ? join(' ', map { defined $_ ? $_ : '' } $start, $end)
               : NONE;

    $self->{ style } = $style;
    $self->{ start } = $start;
    $self->{ end   } = $end;

    # TODO: handle start/end tags and modify start/end that we generate
    # patterns from
    #    $self->{ pre_chomp  } = $config->{ pre_chomp  } || 0;
    #    $self->{ post_chomp } = $config->{ post_chomp } || 0;


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
    my $start   = $self->{ start };
    my $tag_map = shift || {
        start  => [ ],    # list of all start tokens
        regex  => [ ],    # list of regex-based start tokens and tags
        fixed  => { },    # hash mapping fixed start tokens to tags
    };

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


sub tokens {
    my ($self, $input, $output, $text, $start, $pos) = @_;
    my ($token, $type);

    $self->debug("pre-text: <$text>") if DEBUG;
    $output->text_token($text, $pos);
    
    $self->debug("tag starting: <$start>") if DEBUG;
    $pos = pos $$input;
    $token = $output->tag_start_token($start, $pos - length($start));
    
    while (1) {
        $self->debug("\@$pos: ", $self->peek_to_end($input)) if DEBUG;
        
        if ($$input =~ /$NAMESPACE/cog) {
            $self->namespace_token($input, $output, $1, $pos);
        }
        elsif ($$input =~ /$IDENT/cog) {
            if ($type = $self->{ keywords }->{ $1 }) {
                $self->{ grammar }->matched($input, $output, $pos, $1);
            }
            else {
                $output->word_token($1, $pos);
            }
        }
        elsif ($$input =~ /$NUMBER/cog) {
            $output->number_token($1, $pos);
        }
        elsif ($$input =~ /$SQUOTE/cog) {
            $output->squote_token($1, $pos);
        }
        elsif ($$input =~ /$DQUOTE/cog) {
            $output->dquote_token($1, $pos);
        }
        elsif ($$input =~ /$self->{ match_at_end }/cg) {
            $self->debug("matched END: $1") if DEBUG;
            $output->tag_end_token($1, $pos);
            last;
        }
        elsif ($self->{ grammar }->match_nonword($input, $output, $pos)) {
            # OK
        }
#        elsif ($$input =~ /$self->{ match_nw }/cg) {
#            $type = $self->{ nonwords }->{ $1 }
#                || return $self->error_msg( invalid => token => $1 );
#            $type = $type->[1] . '_token';
#            $self->debug("got non-word token: $1 => $type");
#            $output->$type($1, $pos);
#        }
        elsif ($$input =~ /$self->{ match_whitespace }/cg) {
            $output->whitespace_token($1, $pos);
        }
        else {
            return $self->error("Unexpected input: [", $self->peek_to_end($input), "]");
        }
        
        $pos = pos $$input;
    }

    return $token;
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
