package Template::TT3::Dialect;

use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    import      => 'class',
    utils       => 'is_object',
    constants   => 'HASH ARRAY',
    modules     => 'TAGSET_MODULE SCANNER_MODULE',
    accessors   => 'tagset_module scanner_module',
    config      => [
        'tagset_module|class:TAGSET_MODULE|method:TAGSET_MODULE',
        'scanner_module|class:SCANNER_MODULE|method:SCANNER_MODULE',
        'tagset|class:TAGSET',
        'scanner|class:SCANNER',
    ];


sub init {
    my ($self, $config) = @_;
    
    $self->debug("init() tagset with ", $self->dump_data($config)) 
        if DEBUG;
    
    $self->configure($config);

    # if we've been supplied with a tagset object rather than a configuration
    # then we install it straight into tagset_object
    $self->{ tagset_object } = $self->{ tagset }
        if is_object( TAGSET_MODULE, $self->{ tagset } );

    # same for the scanner
    $self->{ scanner_object } = $self->{ scanner }
        if is_object( SCANNER_MODULE, $self->{ scanner } );

    return $self;
}


sub tagset {
    my $self = shift;

    $self->debug("tagset object [$self->{ tagset_object }]")
        if DEBUG;

    # TODO: merge TAGS

    return $self->{ tagset_object } 
        ||= $self->create_tagset;
}


sub create_tagset {
    my $self   = shift;
    my $module = $self->{ tagset_module };
    my $tagset = $self->{ tagset };
    my $params;
    
    # The tagset can be undefined (in which case we used the default 
    # configuration for the tagset_module), an array ref (in which case it's
    # a list of tags for the tagset) or a hash ref (in which case it's a 
    # configuration hash for the tagset).
    if (! $tagset) {
        $params = undef;
    }
    elsif (ref $tagset eq ARRAY) {
        $params = { tags => $tagset };
    }
    elsif (ref $tagset eq HASH) {
        $params = $tagset;
    }
    else {
        return $self->error_msg( invalid => tagset => $tagset );
    }

    $self->debug(
        "instantiating $module with tagset: ", 
        $self->dump_data($tagset), "\n",
        "passing parameters: ", $self->dump_data($params)
    ) if DEBUG;
    
#    debug("instantiating $self->{ tagset_module } with ", $self->dump_data($self->{ tagset })) &&

    class( $module )
        ->load
        ->instance( $params || () );
}


sub scanner {
    my $self = shift;

    return $self->{ scanner_object }
        ||= class( $self->{ scanner_module } )
            ->load
            ->instance( $self->{ scanner } );
}


sub reset {
    my $self = shift;
    delete $self->{ tagset_object  };
    delete $self->{ scanner_object };
}
    
    
1;
