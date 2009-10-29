package Template::TT3::Tag;

use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Tokens',
#    throws   => 'tag',
    constants => 'REGEX NONE',
    patterns  => ':all',
    messages => {
        no_token   => 'No token specified for %s of tag.',
    };
 
our $TAG_STYLE = { };
   

*init = \&init_tag;


sub init_tag {
    my $self   = shift;
    my $config = shift || $self->{ config };
    my $start  = $self->{ start } 
        = delete($config->{ tag_start })
       || delete($config->{ start });
#       || $self->error_msg( no_token => 'start' );
       
    my $end = $self->{ end } 
        = delete($config->{ tag_end })
       || delete($config->{ end });
#       || $self->error_msg( no_token => 'end' );

    my $style = $self->{ tag_style } = 
        ( defined($start) || defined($end) )
            ? join(' ', map { defined $_ ? $_ : '' } $start, $end)
            : NONE;

    my $patterns = $TAG_STYLE->{ $style } ||= do {
        $self->debug("Compiling regexen for tag parser style: $style\n") if $DEBUG;
        $self->init_patterns($start, $end);
    };

    $self->debug("Importing match patterns") if $DEBUG;
    
    # import patterns with a match_prefix, e.g. match_whitespace
    @$self{ map { "match_$_" } keys %$patterns } = values %$patterns;

    # tmp hacks
    $self->{ keywords } = $config->{ keywords };
    $self->{ match_op } = qr{ \G (\+|\-|\*|\/) }x;
    $self->{ ops } = {
        '+' => 'plus',
        '-' => 'minus',
        '*' => 'multiply',
        '/' => 'divide',
    };

    return $self;
}


sub tag_map {
    my $self    = shift;
    my $start   = $self->{ start };
    my $tag_map = shift || {
        start  => [ ],    # list of all start tokens
        regex  => [ ],    # list of regex-based start tokens and tags
        fixed  => { },    # hash mapping fixed start tokens to tags
    };

    if (ref $start eq 'Regexp') {
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


sub init_patterns {
    my ($self, $start, $end) = @_;
    my $eol;

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
    #my $wspace = qr/ \s* (?:$comment\s*)* /sx;
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


sub tokens {
    my ($self, $text, $pretext, $start) = @_;
    my (@tokens, $token, $type, $pos);
    
    $self->debug("tag starting: <$start>") if DEBUG;
    push(@tokens, [tag_start => $start]);
    
    while (1) {
        $pos = pos $$text;

        $self->debug("\@$pos: ", $self->remaining_text($text)) if DEBUG;
        
        if ($$text =~ /$NAMESPACE/cog) {
            $token = $self->namespace_token($text, $1, $pos);
        }
        elsif ($$text =~ /$IDENT/cog) {
            if ($type = $self->{ keywords }->{ $1 }) {
                $token = [$type => $1];
            }
            else {
                $token = [ word => $1 ];
            }
        }
        elsif ($$text =~ /$NUMBER/cog) {
            $token = [ number => $1 ];
        }
        elsif ($$text =~ /$SQUOTE/cog) {
            $token = [ squote => $1 ];
        }
        elsif ($$text =~ /$DQUOTE/cog) {
            $token = [ dquote => $1 ];
        }
        elsif ($$text =~ /$self->{ match_op }/cg) {
            $type = $self->{ ops }->{ $1 }
                || return $self->error_msg( invalid => op => $1 );
            $token = [ $type => $1 ];
        }
        elsif ($$text =~ /$self->{ match_whitespace }/cg) {
            $token = [ whitespace => $1 ];
        }
        elsif ($$text =~ /$self->{ match_at_end }/cg) {
            $self->debug("matched END: $1") if DEBUG;
            push(@tokens, [tag_end => $1]);
            last;
        }
        else {
            return $self->error("Unexpected input: [", $self->remaining_text($text), "]");
        }
        
#        $self->debug('+ ', $token->[0], ' => ', $token->[1]);
        push(@tokens, $token);
    }

    return return wantarray
        ?  @tokens
        : \@tokens;
}


#-----------------------------------------------------------------------
# extra methods 
#-----------------------------------------------------------------------

sub remaining_text {
    my ($self, $text) = @_;
    my $pos = pos $$text;
    # we should be using the proper match_to_end regex but that ignores
    # off leading whitespace which we're trying to preserve for the sake
    # of testing...
    my $result = ($$text =~ /$self->{ match_to_end }/gcsx);
    #my $result = $$text =~ /\G(.*)/gcsx;
    pos $$text = $pos;
    return $result ? $1 : '';
}

1;

