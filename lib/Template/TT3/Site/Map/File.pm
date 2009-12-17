package Template::TT3::Site::Map::File;

use Template::TT3::Class
    version    => 2.71,
    debug      => 0,
    base       => 'Template::TT3::Site::Map',
    filesystem => 'File',
    config     => [
        'file|default|class:FILE',
    ],
    messages => {
    };

use Badger::Codecs 'Codec';


sub init {
    my ($self, $config) = @_;
    my ($file, $codec, $data);

    $self->init_hub($config)
         ->configure($config);

    # we must have a master config specified
    $file = File($self->{ file });

    return $self->error_msg( invalid => 'sitemap file',  $self->{ file } )
        unless $file->exists;

    # guess the data codec from the file extension if we don't have one 
    $codec = $self->{ codec } || $file->extension;

    $file->try->codec($codec)
        || return $self->error_msg( invalid => 'sitemap file extension', $codec );
    
    # read the file data, then stash everything away for later
    $data = $file->data;

    $self->{ data } = $data;
    $self->{ file } = $file;
    $self->{ dir  } = $file->directory;

    $self->debug("loaded sitemap data: ", $self->dump_data($data)) if DEBUG;

    # bit of a hack - we stuff the knowledge that we've grokked about the
    # directory layout back into the config so that the calling T~Site object
    # can examine it.
    $config->{ dir } 
        ||= $data->{ dir } 
        || {
            metadata => $file->directory,
            root     => $file->parent(1),
        };

    $self->debug("set dir from sitemap file to $config->{ dir }\n") if DEBUG;
    
    return $self;
}


1;
