package Template::TT3::Tagset;

use Template::TT3::Tags;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    utils     => 'params',
    constants => 'HASH ARRAY REGEX DEFAULT',
    constant  => {
        TAGS  => 'Template::TT3::Tags',
    },
    messages  => {
        no_tag_spec => 'No tag set specification provided for "%s" tag.',
    };


sub init {
    my ($self, $config) = @_;
    $self->init_tagset($config);
    $self->{ config } = $config;
    return $self;
}


sub init_tagset {
    my ($self, $config) = @_;
    my $tags     = $self->class->list_vars( TAGS => $config->{ tags } );
    my $factory  = $self->TAGS;
    my $tagset   = $self->{ tags  } = { };
    my $tagnames = $self->{ names } = [ ];
    my (@pending, $name, $spec, $type, $tag, $default);
    
    $self->debug('init_tagset()  tags are: ', $self->dump_data($tags)) if DEBUG;
    
    @pending = @$tags;
    
    while (@pending) {
        $name = shift @pending;
        $self->debug("name: $name") if DEBUG;

        if (ref $name eq ARRAY) {
            # expand arrays onto start of pending list 
            unshift(@pending, @$name);
            next;
        }
        elsif (ref $name eq HASH) {
            unshift(@pending, %$name);
            next;
        }

        return $self->error_msg( no_tag_spec => $name )
            unless @pending;
            
        $spec = shift @pending;
        $self->debug("spec: $spec") if DEBUG;

        $spec = { style => $spec } 
            unless ref $spec eq HASH;
            
        $type = $spec->{ type } ||= $name;
        
        # add the tag name to the order list if we haven't already seen it
        push(@$tagnames, $name)
            unless $tagset->{ $name };
        
        $tagset->{ $name } = $factory->tag( $type => $spec )
            || return $self->error_msg( invalid => tag => $type );
    }
    
    $self->debug("tag order is: ", $self->dump_data($tagnames)) if DEBUG;
#    $self->debug("generated tags: ", $self->dump_data($tagset));
}


sub tags {
    my $self = shift;
    my $tags = $self->{ tags };
    my @tags = map { $tags->{ $_ }    }
                  @{ $self->{ names } };
    
    return wantarray
        ?  @tags
        : \@tags;
}


sub tag {
    my $self = shift;
    my $tags = $self->{ tags };
    return $tags unless @_;
    my $name = shift;
    $name = $self->{ names }->[0] if $name eq DEFAULT;
    return $tags->{ $name };
}

   
sub tag_map {
    my $self    = shift;
    my $tag_map = $self->{ tag_map } = shift || {
        start  => [ ],    # list of all start tokens
        regex  => [ ],    # list of regex-based start tokens and tags
        fixed  => { },    # hash mapping fixed start tokens to tags
    };

    # ask the tags to provide details (into $tag_map) of their start tags
    foreach my $tag ($self->tags) {
        $self->debug("adding tag to tag map: $tag\n") if DEBUG;
        $tag->tag_map($tag_map);
    }

    # quotemeta() escape any start tokens that aren't already regexen
    my @regex = map { 
        ref $_ eq REGEX ? $_ : quotemeta($_);
    } @{ $tag_map->{ start } };

    $self->debug("generating tagset for ", scalar(@regex), " tag(s)\n") if DEBUG;

    if (@regex) {
        # generate a regex to match a chunk of text (possible of zero length)
        # up to the start of any tag
        my $regex = join('|', @regex);
        $tag_map->{ match_to_tag } = qr/ \G (.*?) ($regex) /sx;
        $self->debug("generated tagset regex: $regex\n") if DEBUG;
    }
    else {
        # generate a regex to matches nothing, effectively acting as a short
        # circuit - if a template has no tags defined then we catch the entire 
        # text block using the to_end_regex defined below
        $tag_map->{ match_to_tag } = qr//;
        $self->debug("no tag_map regex generated\n") if DEBUG;
    }
    
    return $tag_map;
}


sub change {
    my $self   = shift;
    my $config = @_ == 1 ? shift : params(@_);
    my $tags   = $self->{ tags };
    my $names  = $self->{ names };
    my ($name, $tag, $spec);

    if (! ref $config) {
        $config = {
            default => $config,
        };
    }
    elsif (ref $config eq ARRAY) {
        $config = {
            default => $config,
        }
    }
    elsif (ref $config ne HASH) {
        return $self->error_msg( invalid => tags => $config );
    }
    
    # ask the tags to provide details (into $tag_map) of their start tags
    my ($not_first, $changed) = (0) x 2;
    
    $self->debug("change() => ", $self->dump_data($config)) if DEBUG;
    
    foreach $name (@$names) {
        $tag    = $tags->{ $name };
        $spec   = $config->{ $name };
        # first item aka 'default'
        $spec ||= $config->{ default }
            unless $not_first++; 

        next unless defined $spec;
        $changed++;
        
        $self->debug("changing tag $name => ", $self->dump_data($spec)) if DEBUG;
        $tag->change($spec);
    }
    
    my @bad_uns = 
        grep { not ($tags->{ $_ } || $_ eq DEFAULT) } 
        keys %$config;
        
    $self->error_msg( invalid => tags => join(', ', sort @bad_uns) )
        if @bad_uns;
    
    return $changed;
}


sub reset {
    my $self = shift;

    foreach my $tag ($self->tags) {
        $tag->reset;
    }
    
    return $self;
}
    

1;

__END__

=pod

=head2 init_tagset()

We allow tag sets to be specified using hash refs for simple mapping by name
where the order of tags isn't important.

    $TAGS = { inline => { ... }, outline => { ... }, etc }

Or they can be defined using list refs for those times when the order of tags
matching is important. For example, if you have a '$' tag for embedding
"naked" variables in the template text then you (probably) also want a '\$'
tag (or a more generic '\' escaping tag) to allow the user to escape dollar
signs that shouldn't be interpreted as variables. The scanner will *usually*
do the right thing by matching tokens in order of length from longest to
shortest. So '\$' will get (correctly) matched before '$'. However, in the case
of '$' vs '\' either could come first (due to the unpredictable order of hash
array contents).

In those cases it's better to be explicit and specify the tags using a list
reference. That avoids any ambiguity.

   $TAGS = [ inline => { ... }, outline => { ... } ]

Subsequent entries will not be added to the order. However, the values they
define will replace those of the earlier occurence. For example:

   $TAGS = [ 
      inline  => { ... }, 
      outline => { ... } 
      inline  => 0,
   ]

The above ends up being equivalent to:

   $TAGS = [ 
      inline  => 0, 
      outline => { ... } 
   ]

The original order is preserved, but the latter value supersedes the earlier
one. In this example, the end result is that the inline tag has been disabled.
Note that we construct the $TAGS list from a number of sources. So the module
may define the first 'inline' tags, but the user supersedes it by passing the
'inline => 0' parameter.
