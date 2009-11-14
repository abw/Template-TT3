package Template::TT3::Tag::Closed;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag',
    import    => 'class',
    utils     => 'numlike',
    patterns  => ':all',
    constants => ':chomp SPACE REGEX NONE CODE',
    constant  => {
        REGEX_GROUP => '\G([%s])',
        SKIP_TAG    => 0,
        CONTINUE    => 1,
    },
    messages  => {
        bad_chomp => 'Invalid %s_chomp option specified: %s',
        bad_flag  => 'Invalid flag at %s of tag: %s',
    };


our $PRE_CHOMP = {
    '+' => 1,       # do nothing
    '-' => \&pre_chomp_one,
    '=' => \&pre_chomp_collapse,
    '~' => \&pre_chomp_all,
    '#' => \&comment,
};

our $POST_CHOMP = {
    '+' => 1,       # do nothing
    '-' => \&post_chomp_one,
    '=' => \&post_chomp_collapse,
    '~' => \&post_chomp_all,
};



#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------

sub init {
    my $self   = shift;
    my $config = shift || $self->{ config };
    $self->init_flags($config);
    $self->init_tag($config);
    $self->{ config } ||= $config;
    return $self;
}


sub init_flags {
    my $self       = shift;
    my $config     = shift || $self->{ config };
    my $pre_chomp  = $config->{ pre_chomp  } || 0;
    my $post_chomp = $config->{ post_chomp } || 0;
    my $handler;
    
    $self->debug('init_flags()') if DEBUG;

    # massage the pre_chomp option
    if ($pre_chomp) {
        # Convert a numerical value to the pre chomp flag, e.g. 1 => '-'
        if (numlike $pre_chomp) {
            $pre_chomp = PRE_CHOMP_FLAGS->[$pre_chomp]
                || return $self->error_msg( bad_chomp => pre  => $pre_chomp  );
        }

        # Lookup the handler associated with it
        $handler = $PRE_CHOMP->{ $pre_chomp }
            || return $self->error_msg( bad_chomp => pre  => $pre_chomp  );

        # Install it if it's a code ref.  Any other true value is assumed to 
        # mean "That's OK, there's nothing to do, we're all happy here"
        $self->{ pre_chomp } = $handler
            if ref $handler eq CODE;
    }

    # same again for post_chomp option... you don't need comments this time
    if ($post_chomp) {
        if (numlike $post_chomp) {
            $post_chomp = POST_CHOMP_FLAGS->[$post_chomp]
                || return $self->error_msg( bad_chomp => post => $post_chomp  );
        }
        $handler = $POST_CHOMP->{ $post_chomp }
            || return $self->error_msg( bad_chomp => post => $post_chomp  );
            
        $self->{ post_chomp } = $handler
            if ref $handler eq CODE;

    }

    if (DEBUG) {
        $self->debug("installed pre_chomp handler: $pre_chomp") 
            if $self->{ pre_chomp };
        $self->debug("installed post_chomp handler: $post_chomp")
            if $self->{ post_chomp };
    }
    
    # Construct regex to match a pre_chomp flag
    $pre_chomp = '[' . quotemeta( join('', keys %$PRE_CHOMP) ) . ']';
    $self->{ match_pre_chomp } = qr/ \G ($pre_chomp) /x;

    # Same thing for post_chomp flag, but we're going to glue it onto the 
    # start of the end_token in init_tag_style().  This allows us to match 
    # the end flag and token in one go.
    $post_chomp = '[' . quotemeta( join('', keys %$POST_CHOMP) ) . ']?';
    $self->{ match_post_chomp } = $post_chomp;
        
    return $self;
}


sub init_tag_style {
    my ($self, $style, $start, $end) = @_;

    if ($end) {
        $self->debug("gluing flags $self->{ match_post_chomp} onto end token $end")
            if DEBUG;
        $end = quotemeta($end) unless ref $end eq REGEX;
        $end = qr/ $self->{ match_post_chomp } $end /x;
        $self->debug("new end regex: $end") if DEBUG;
    }

    $style ||= ( defined($start) || defined($end) )
               ? join(' ', map { defined $_ ? $_ : '' } $start, $end)
               : NONE;
    
    return ($style, $start, $end);
}



#-----------------------------------------------------------------------
# Scanning methods
#-----------------------------------------------------------------------

sub scan {
    my ($self, $input, $output, $text, $start, $pos) = @_;
    my $start_pos = $pos - length $start;
    my ($token, $type, $chomp);

    # Look for a chomping flag at the start
    if ($$input =~ /$self->{ match_pre_chomp }/cgx) {
        $self->debug("found pre-chomp flag: $1") if DEBUG;
        $chomp = $PRE_CHOMP->{ $1 }
            || return $self->error_msg( bad_flag => start => $1  );
    }

    # Take care of the preceding text chunk
    if (defined $text && length $text) {
        $self->debug("pre-text: <$text>") if DEBUG;

        if ($chomp ||= $self->{ pre_chomp }) {
            # Let the chomp handler take care of the preceding text.  If it
            # returns a false value then the whole tag is short-circuited
            $self->$chomp($input, $output, $text, $start, $pos)
                || return;
        }
        else {
            # or push it to the token list ourselves
            $output->text_token($text, $pos);
        }
    }
    
    $self->debug("tag starting: <$start>") if DEBUG && $start;

    # output the tag start token
    $pos   = pos $$input;
    $token = $output->tag_start_token($start, $pos - length($start))
        if defined $start && length $start;
    
    return $self->tokens($input, $output, $token, $pos);
    
    # TODO: post-chomp
}


sub pre_chomp_one {
    my ($self, $input, $output, $text, $start, $pos) = @_;

    # remove whitespace up to and including the first preceding newline
    if ($text =~ s/ ((\n|^) [^\S\n]*) \z //mx) {
        $output->text_token($text, $pos);
        $pos = pos($$input) - length($1);
        $output->whitespace_token($1, $pos);
    }
    else {
        $output->text_token($text, $pos);
    }
    
    return CONTINUE;
}


sub pre_chomp_all {
    my ($self, $input, $output, $text, $start, $pos) = @_;

    # remove all preceding whitespace
    if ($text =~ s/ (\s+) \z //x ) {
        $output->text_token($text, $pos);
        $pos = pos $$input;
        $output->whitespace_token($1, $pos - length $1);
    }
    else {
        $output->text_token($text, $pos);
    }

    return CONTINUE;
}
    

sub pre_chomp_collapse {
    my ($self, $input, $output, $text, $start, $pos) = @_;

    # remove all preceding whitespace and replace with a single space
    if ($text =~ s/ (\s+) \z //x ) {
        $output->text_token($text, $pos);
        $pos = pos $$input;
        $output->whitespace_token($1, $pos - length $1);
    }
    else {
        $output->text_token($text, $pos);
    }

    # TODO: make this a synthetic text token so we can tell the difference
    # between real text and generated text
    $output->text_token(SPACE, $pos);

    return CONTINUE;
}


sub comment {
    my ($self, $input, $output, $text, $start, $pos) = @_;

    $output->text_token($text, $pos);
    $pos  = pos $$input;
    $pos -= length($start);
    
    $$input =~ /$self->{ match_to_end }/cg
        || return $self->error_msg( no_end => $self->{ end } );
        
    $output->comment_token($start . $1, $pos);

    return SKIP_TAG;
}
    

1;

