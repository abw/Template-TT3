package Template::TT3::Tagset;

use Template::TT3::Tags;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    constants => 'HASH',
    constant  => {
        TAGS  => 'Template::TT3::Tags',
    };


sub init {
    my ($self, $config) = @_;
    $self->init_tagset($config);
    $self->{ config } = $config;
    return $self;
}


sub init_tagset {
    my ($self, $config) = @_;
    my $tags    = $self->class->hash_vars( TAGS => $config->{ tags } );
    my $factory = $self->TAGS;
    my $tagset  = { };
    
    while (my ($name, $spec) = each %$tags) {
        $spec = { style => $spec } 
            unless ref $spec eq HASH;
            
        my $type = $spec->{ type } || $name;
        $tagset->{ $name } = $factory->tag( $type => $spec )
            || return $self->error_msg( invalid => tag => $type );
    }
    
    $self->{ tags } = $tagset;
    
#    $self->debug("generated tags: ", $self->dump_data($tagset));
}


sub tags {
    my $self = shift;
    my $tags = $self->{ tags };
#    $self->debug("tags() => $tags");
    [ values %$tags ];
}
    

1;
