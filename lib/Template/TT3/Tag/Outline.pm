package Template::TT3::Tag::Outline;

use Template::TT3::Grammar::TT3;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag',
    import    => 'class',
    utils     => 'numlike',
    constants => ':chomp SPACE REGEX NONE CODE',
    constant  => {
        GRAMMAR     => 'Template::TT3::Grammar::TT3',
        SKIP_TAG    => 0,
        CONTINUE    => 1,
    },
    messages  => {
        bad_chomp => 'Invalid %s_chomp option specified: %s',
        bad_flag  => 'Invalid flag at %s of tag: %s',
    };


#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------
 
sub init {
    my $self   = shift;
    my $config = shift || $self->{ config };
    $self->init_flags($config);
    $self->init_tag($config);
    $self->init_grammar($config);   # implemented by us
    $self->{ config } = $config;
    return $self;
}


sub init_tag_style {
    my ($self, $style, $start, $end) = @_;

    if ($end) {
        $self->debug(
            "gluing flags $self->{ match_post_chomp} onto end token $end"
        ) if DEBUG or 1;
        
        $end = quotemeta($end) unless ref $end eq REGEX;
        $end = qr/ $self->{ post_chomp_chars }? $end /x;
        
        $self->debug("new end regex: $end") if DEBUG or 1;
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
    my ($self, $input, $output, $scope, $text, $start, $pos) = @_;
    my $start_pos = pos($$input) - length $start;
    my ($token, $type, $chomp, $end);

    # Look for a chomping flag at the start
    if ($$input =~ /$self->{ match_pre_chomp }/cgx) {
        $self->debug("found pre-chomp flag: $1") if DEBUG;
        $chomp = $PRE_CHOMP->{ $1 }
            || return $self->error_msg( bad_flag => start => $1  );
        $start .= $1;
    }

    # Take care of the preceding text chunk
    if (defined $text) {
        $self->debug("pre-text: <$text>") if DEBUG;

        if ($chomp ||= $self->{ pre_chomp }) {
            # Let the chomp handler take care of the preceding text.  If it
            # returns a false value then the whole tag is short-circuited
            $self->$chomp($input, $output, $text, $start, $pos)
                || return;
        }
        else { 
            # or push it to the token list ourselves
            $output->text_token($text, $pos) if length $text;
        }
    }
    
    $self->debug("tag starting: <$start>") if DEBUG && $start;

    # output the tag start token
    $output->tag_start_token($start, $start_pos)
        if defined $start && length $start;
    
    # tokenise the tag content
    $end = $self->tokenise($input, $output, $scope);

    $self->debug("matching [$end] post-chomp: $self->{ match_post_chomp }")
        if DEBUG;

    # look to see if the end token contained a post-chomp flag
    if ($end && $end =~ /$self->{ match_post_chomp }/) {
        $self->debug("found post-chomp flag: $1") if DEBUG;
        $chomp = $POST_CHOMP->{ $1 }
            || return $self->error_msg( bad_flag => end => $1  );
    }
    else {
        $chomp = undef;
    }

    $pos = pos $$input;
    
    if ($chomp ||= $self->{ post_chomp }) {
        # Let the chomp handler take care of the following text.
        $self->debug("calling post-chomp handler: $end") if DEBUG;
        $self->$chomp($input, $output, $end, $pos);
    }

    return CONTINUE;
}

1;