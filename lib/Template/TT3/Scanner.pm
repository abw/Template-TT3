package Template::TT3::Scanner;

use Template::TT3::Tagset::TT3;
use Template::TT3::Tokens;
use Template::TT3::Scope;
use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Base',
    accessors  => 'tagset',
    utils      => 'is_object',
    constants  => 'REGEX HASH ARRAY',
    constant   => {
        TAGSET => 'Template::TT3::Tagset',
        TOKENS => 'Template::TT3::Tokens',
        SCOPE  => 'Template::TT3::Scope',
    },
    config     => [
        'tagset|class:TAGSET|method:TAGSET',
        'tokens|class:TOKENS|method:TOKENS',
        'scope|class:SCOPE|method:SCOPE',
    ],
    messages   => { 
        no_tag => 'No tag found matching start token: %s',
    };

# This over-rides the default TAGSET constant above.  We use TAGSET as the
# definition of the base class that any valid tagset object should be an
# instances of (or subclass of).  But our default tagset is the TT3 one.
our $TAGSET = 'Template::TT3::Tagset::TT3';

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
    my $class   = $self->class;
    my $tagset  = $self->{ tagset };

    if (is_object( TAGSET, $tagset )) {
        # got a tagset object, that's OK
        $self->debug("got pre-existing tagset object: $tagset") if DEBUG;
    }
    elsif (ref $tagset) {
        $self->debug("got tagset reference: ", $self->dump_data($tagset)) if DEBUG;
        my @classes = grep { ! ref } $class->all_vars('TAGSET'), $self->TAGSET;
        $self->debug("candidates for tagset class: ", join(', ', @classes)) if DEBUG;
        my $tclass = $classes[0];
        $tagset = $tclass->new( tags => $config->{ tagset } );
        $self->debug("created new tagset object: $tagset") if DEBUG;
    }
    else {
        $self->debug("creating new $tagset tagset object: ", $self->dump_data($config->{ tagset })) if DEBUG;
        $tagset = $tagset->new( tags => $config->{ tagset } );
    } 
    
    $tagset->change( $config->{ tags } )
        if $config->{ tags };
    
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
    my $tag_map = $self->{ tag_map } = $self->{ tagset }->tag_map;

    $self->debug("init_tags()\n") if DEBUG;
    $self->debug("tag_map: ", $self->dump_data($tag_map), "\n") if DEBUG;

    # import the regex to match all tags in the tag set
    $self->{ match_to_tag } = $tag_map->{ match_to_tag };
    
    # define a regex to match everything from the current position to the end
    $self->{ match_to_end } = qr/ \G (.*) $/sx;

    return $tag_map;
}


sub scan {
    my ($self, $input, $output, $scope) = @_;

    # define a new scope for this scanner and an output list if undefined
    my $config = $self->{ config };
    local $config->{ scanner } = $self;
    $scope ||= $self->{ scope };

    return $self->tokens(
        ref $input ? $input : \$input,
        $output || $self->{ tokens }->new($config),
        $scope->new($config),
    );
}


sub tokens {
    my ($self, $input, $output, $scope) = @_;
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
            $tag->scan($input, $output, $scope, $text, $start, $pos);
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

    # add the terminator that marks the end of file
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


sub tags {
    my ($self, $tags) = @_;
    $self->debug("setting tags: ", $self->dump_data($tags)) if DEBUG;
    $self->{ tagset }->change($tags);
    $self->init_tags;
}

    

1;
