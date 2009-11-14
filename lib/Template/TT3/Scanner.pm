package Template::TT3::Scanner;

use Template::TT3::Tagset::TT3;
use Template::TT3::Tokens;
use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Base',
    constants  => 'REGEX',
    constant   => {
        TAGSET => 'Template::TT3::Tagset::TT3',
        TOKENS => 'Template::TT3::Tokens',
    },
    config     => [
        'tagset|class:TAGSET|method:TAGSET',
        'tokens|class:TOKENS|method:TOKENS',
    ],
    messages   => { 
        no_tag => 'No tag found matching start token: %s',
    };


*init = \&init_scanner;


sub init_scanner {
    my ($self, $config) = @_;
    $self->debug("INIT: ", $self->dump_data($config)) if DEBUG;
    $self->configure($config);
    $self->init_tagset($config);
    $self->init_tags($config);
    $self->{ config } = $config;
    return $self;
}


sub init_tagset {
    my $self    = shift;
    my $config  = shift || $self->{ config };
    my $tagset  = $self->{ tagset };  #class->any_var( TAGSET => $config->{ tagset } );

    $tagset = $tagset->new($config)
        unless ref $tagset;
        
    $self->{ tagset } = $tagset;
    $self->{ tags   } = $tagset->tags;
    
    if (DEBUG) {
        $self->debug("tagset: $tagset");
        $self->debug("tags: $self->{ tags }");
    }

    return $self;
}


sub init_tags {
    my $self    = shift;
    my $config  = shift || $self->{ config };
#    my $tags    = $self->class->list_vars( TAGS => $config->{ tags } );
    my $tags    = $self->{ tags };
    my $tag_map = $self->{ tag_map } = { };

    $self->debug("init_scanner()\n") if DEBUG;
    $self->debug("** tags: ", $self->dump_data($tags)) if DEBUG;
    
    # ask the tags to provide details (into $tag_map) of their start tags
    foreach my $tag (@$tags) {
        $self->debug("adding tag to tag map: $tag\n") if DEBUG;
        $tag->tag_map($tag_map);
    }

    $self->debug("tag_map: ", $self->dump_data($tag_map), "\n") if DEBUG;

    # quotemeta() escape any start tokens that aren't already regexen
    my @regex = map { 
        ref $_ eq REGEX ? $_ : quotemeta($_);
    } @{ $tag_map->{ start } };

    $self->debug("generating tagset for ", scalar(@regex), " tag(s)\n") if DEBUG;

    if (@regex) {
        # generate a regex to match a chunk of text (possible of zero length)
        # up to the start of any tag
        my $regex = join('|', @regex);
        $self->{ match_to_tag } = qr/ \G (.*?) ($regex) /sx;
        $self->debug("generated tagset regex: $regex\n") if DEBUG;
    }
    else {
        # generate a regex to matches nothing, effectively acting as a short
        # circuit - if a template has no tags defined then we catch the entire 
        # text block using the to_end_regex defined below
        $self->{ match_to_tag } = qr//;
        $self->debug("no tag_map regex generated\n") if DEBUG;
    }
    
    # define a regex to match everything from the current position to the end
    $self->{ match_to_end } = qr/ \G (.*) $/sx;

    return $tag_map;
}


sub scan {
    my ($self, $input, $output) = @_;
    return $self->tokens(
        ref $input ? $input : \$input,
        $output || $self->{ tokens }->new( $self->{ config } ),
    );
}


sub tokens {
    my ($self, $input, $output) = @_;
    my ($pos, $text, $start, $tag);
    
    while (1) {
        $pos = pos $$input || 0;
        
        if ($$input =~ /$self->{ match_to_tag }/gc) {
            # We've matched a chunk of text up to the next tag start token.
            # We find the tag object corresponding to the tag start token 
            # and call its tokens() method.  We pass the preceeding text
            # in case the tag wants to modify it (e.g. pre-chomping) before
            # committing it to the output stream.
            ($text, $start) = ($1, $2);
            
            $tag = $self->{ tag_map }->{ fixed }->{ $2 }
               ||= $self->match_regex_tag($2)
               ||  return $self->error_msg( invalid => tag => $start );
               
            # TODO: may want to pass \$text and \$start references to avoid
            # more string copying
            $tag->scan($input, $output, $text, $start, $pos, $self);
        }
        elsif ($$input =~ /$self->{ match_to_end }/gc) {
            # We've matched the rest of the text after the last tag (or the 
            # entire file if there weren't any tags embedded).
            $output->text_token($1, $pos)
                if length $1;
            last;
        }
        else {
            return $self->error("Run out of text");
        }
    }

    $output->eof_token();
    return $output->finish;
}


sub tag_map {
    my $self = shift;
    $self->{ tag_map } || $self->init_tags;
}


sub match_tag {
    my ($self, $start, $tag_map) = @_;
    $tag_map ||= $self->{ tag_map } || $self->init_tags;

    # see if $start matches a fixed tag start token or can be match by
    # any regex-based matches. 
    return $tag_map->{ fixed }->{ $start }
        ||= $self->match_regex_tag($start, $tag_map);
}


sub match_regex_tag {
    my ($self, $start, $tag_map) = @_;
    $tag_map ||= $self->{ tag_map } || $self->init_tags;

    # Iterate through all the tags that use regexen to match their start 
    # token, and try to match $start against each.  
    foreach my $match (@{ $tag_map->{ regex } }) {
        return $match->[1]
            if $start =~ $match->[0];
    }

    # if the caller is using the regex that this object generated, then
    # a matched token should always match either as a fixed start or regex
    return $self->error_msg( no_tag => $start );
}



1;
