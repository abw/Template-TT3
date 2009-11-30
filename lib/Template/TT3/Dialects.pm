package Template::TT3::Dialects;

use Badger::Factory::Class
    version     => 3.00,
    debug       => 0,
    constants   => 'HASH',
    item        => 'dialect',
    base        => 'Template::TT3::Base',
    path        => 'Template(X)::(TT3::|)Dialect',
    constants   => DEFAULT,
    map         => {
        # special cases for capitalisation
        TT3     => 'TT3',
        tt3     => 'TT3',
        default => 'TT3',
    };


sub init {
    my ($self, $config) = @_;
    $self->debug("init() with ", $self->dump_data($config)) if DEBUG;
    $self->init_factory($config);
    $self->{ config } = $config->{ dialects } || $config;
    $self->debug("dialects config: ", $self->dump_data($self->{ config })) if DEBUG;
    return $self;
}


sub type_args {
    my $self = shift;
    my $type = shift || DEFAULT;
    return ($type, @_);
}


sub found {
    my ($self, $type, $item, $args) = @_;
    
    $self->debug("Found result: $type => $item") if DEBUG;

    $self->debug("Returning cached dialect: $self->{ cache }->{ $type }") 
        if DEBUG && $self->{ cache }->{ $type };

    return $self->{ cache }->{ $type } ||= do {
        my $config = $self->{ config };
        my $params = $config->{ $type } || $config;
        my ($dialect, $module);
        
        # If we've got a hash ref as an item then we need to look for a 
        # 'dialect' item in it.  If that's not defined then we try to load
        # the module named by the type name (e.g. tt3 => { ... } loads the
        # TT3 dialect).  Otherwise we load the default dialect.
        if (ref $item eq HASH) {
            $self->debug(
                "found hash config for $item dialect: ", 
                $self->dump_data($item)
            ) if DEBUG;
            
            $dialect = $item->{ dialect } || $type;
            $module  = $self->find($dialect)
                || return $self->error_msg( invalid => dialect => $dialect );
                
            $self->debug("fell back on $dialect mapping to $module") if DEBUG;
            
            # TODO: config merging?
        }
        else {
            $module = $item;
        }

        $self->debug(
            "instantiating dialect $type as $module using config: ", 
            $self->dump_data($params)
        ) if DEBUG;
        
        # add default name for dialect
        $params->{ name } ||= $type;

        $module->new($params);
    };
}



1;