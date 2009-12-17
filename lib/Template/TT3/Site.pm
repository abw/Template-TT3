package Template::TT3::Site;

use Template::TT3::Site::Page;
use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    import     => 'class',
    base       => 'Template::TT3::Base',
    utils      => 'textlike params self_params',
    modules    => 'SITEMAPS_MODULE',
    filesystem => 'File Dir VFS',
    accessors  => 'sitemap',
    constants  => 'HASH :scheme',
    constant   => {
        PAGE     => 'Template::TT3::Site::Page',
        ENGINE   => 'Template::TT3::Engine::TT3',
        BUILDER  => 'Template::TT3::Site::Builder',
        REPORTER => 'Template::TT3::Site::Reporter',
    };


our $MATCH_EXT = qr/\.([^\.]+)$/;

our $DIRS = {
    pages   => 'templates/pages',
    library => 'templates/library',
    output  => 'html',
};  


#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->init_hub($config)
         ->init_map($config)
         ->init_dir($config);

#    $self->{ config } = $config;

    return $self;
}


sub init_map {
    my ($self, $config) = @_;
    my $map = $config->{ map } 
        || $self->class->var('MAP')
        || return $self->error_msg( missing => 'map' );
        
    my ($type, $args);
    
    if (ref $map eq HASH) {
        $type = $map->{ type } || DATA_SCHEME;
        $args = $map;
    }
    elsif (textlike $map) {
        $type = FILE_SCHEME;
        $args = { file => $map };
    }
    else {
        return $self->error_msg( invalid => map => $map );
    }
    
    $self->{ sitemap } = $self->hub->sitemap( $type, $args );

    $self->debug("created site map: ", $self->{ map }) if DEBUG;

    # hack - the site map can stuff a 'dir' item back into $args containing
    # information about the directory locations/layout gleaned from the 
    # master config file.  We copy it into the master config so that 
    # init_dir() can have a crack at it after we're done in init_map()
    $config->{ dir } ||= $args->{ dir };

    # not sure what to do with this...
    my $data = $self->{ sitemap }->data;
    $self->{ config } = {
        %$data,
        %$config,
    };
    
    $self->{ site } = $self->{ config }->{ site };
    $self->debug("loaded site: ", $self->dump_data($self->{ site })) if DEBUG;
    $self->debug("merged config: ", $self->dump_data($self->{ config })) if DEBUG;
    
    return $self;
}


sub init_dir {
    my ($self, $config) = @_;
    my ($spec, $root, $dirs);
    
    # The site map may already have initialised the dirs from information
    # contained in the config file(s)
    return if $self->{ dir };
    
    # 'dir' (or 'root') can be specified as a single directory path or a 
    # hash ref containing a 'root' item and any other directories we might
    # want to use, e.g. { root => '/tmp/foo', pages => 'templates/pages' }
    $spec = $config->{ dir } || $config->{ root }
        || return $self->error_msg( missing => 'root directory' );
    
    $spec = { root => $spec }
        unless ref $spec eq HASH;

    $root = $spec->{ root }
        || return $self->error_msg( missing => 'root directory' );
    
    $root = Dir($root)->must_exist;
    
    # merge the director(y|ies) specified with the defaults in $DIRS
    $dirs = $self->class->hash_vars( DIRS => $spec );
    
    # we've done this one already
    delete $dirs->{ root };
    
    # resolve all the directories relative to the site root
    $dirs = {
        root => $root,
        map { $_ => $root->dir( $dirs->{ $_ } ) }
        keys %$dirs
    };

    $self->debug("site dirs: ", $self->dump_data($dirs)) if DEBUG;
    
    $self->{ dir } = $dirs;
    
    return $self;
}



#-----------------------------------------------------------------------
# Methods for accessing configuration data
#-----------------------------------------------------------------------


sub dir {
    my $self = shift;
    my $dirs = $self->{ dir };
    return @_
        ? $dirs->{ $_[0] } || $dirs->{ root }->{ $_[0] }
        : $dirs->{ root };
}


sub build_config {
    my $self   = shift;
    my $config = $self->{ config }->{ build } || { };
    return @_
        ? $config->{ $_[0] }
        : $config;
}


sub find_config {
    my $self   = shift;
    my $config = $self->{ config }->{ find } || { };
    return @_
        ? $config->{ $_[0] }
        : $config;
}
        

sub engine_config {
    my $self   = shift;
    my $config = $self->{ config }->{ engine } || { };
    $self->debug("$self engine config: ", $self->dump_data($self->{ config })) if DEBUG;
    return @_
        ? $config->{ $_[0] }
        : $config;
}
        

#-----------------------------------------------------------------------
# build methods
#-----------------------------------------------------------------------

sub build {
    my $self     = shift;
    my $config   = $self->{ config };
    my $builder  = $self->builder(@_);
    my $buildcfg = $config->{ build };
    
    foreach (qw( verbose summary )) {
        $buildcfg->{ $_ } = $config->{ $_ } 
            unless defined $buildcfg->{ $_ };
    }

    $builder->report_preview
        if $buildcfg->{ verbose };

    $builder->report_building
        if $buildcfg->{ summary }
        or $buildcfg->{ verbose };

    $self->visit_pages($builder);

    $builder->report_summary
        if $buildcfg->{ summary }
        or $buildcfg->{ verbose };
}


sub builder {
    my ($self, $params) = self_params(@_);
    my $config   = $self->{ config };
    my $findcfg  = $self->find_config;
    my $buildcfg = $self->build_config;
    my $reporter = $self->reporter({ %$buildcfg, %$params });
    
    $self->debug("find config: ", $self->dump_data($findcfg)) if DEBUG;
    
    return class( $self->BUILDER )->load->instance(
        site     => $self,
        reporter => $reporter,
#        %$config,
        %$buildcfg,
        %$findcfg,
        %$params,
    );
}


sub reporter {
    my $self = shift;
    class($self->REPORTER)->load->instance(@_);
}


sub visit_pages {
    shift->input_filesystem->visit(@_);
}


sub input_filesystem {
    my $self = shift;
    return $self->{ input_fs }
       ||= VFS->new( root => $self->{ dir }->{ pages } );
}


sub output_filesystem {
    my $self = shift;
    return $self->{ output_fs }
       ||= VFS->new( root => $self->{ dir }->{ output } );
}


sub input_file {
    shift->input_filesystem->file(@_);
}


sub output_file {
    my ($self, $uri) = @_;
    my $map  = $self->find_config('suffix');
    if ($map) {
        $uri =~ s/$MATCH_EXT/'.'.($map->{$1}||$1)/e;
    }
    return $self->output_filesystem->file($uri);
}


sub engine {
    my $self = shift;
    return $self->{ engine } ||= do {
        my $engcfg = $self->engine_config;
        # TODO: merge this properly
        $engcfg->{ template_path } = [
            $self->dir('pages'), 
            $self->dir('library'),
        ];
        $engcfg->{ output_path } = $self->dir('output');
        $self->debug("creating engine: ", $self->dump_data($engcfg)) if DEBUG;
        class($self->ENGINE)->load->instance($engcfg);
    };
}

#-----------------------------------------------------------------------
# page methods
#-----------------------------------------------------------------------

sub page {
    my $self   = shift;
    my $params = (@_ == 1 && ref $_[0] ne HASH)
        ? { uri => shift }
        : params(@_);
    my ($uri, $file);

    # see if we can determine a missing uri from a file (or something else..)
    unless ($params->{ uri }) {
        if ($file = $params->{ file }) {
            $params->{ uri } = File($file)->absolute;
        }
    }
               
    $uri = $params->{ uri }
        || return $self->error_msg( missing => 'uri' );

    my $data = $self->{ sitemap }->page($uri);
    
    return $self->PAGE->new(
        site => $self,
        page => $data,
        uri  => $uri,
    );
}


sub tt_dot {
    my ($self, $name) = @_;
    return $self->{ site }->{ $name };
}


# do this at the end so it doesn't affect any use of Perl's map 
class->alias( map => 'sitemap' );

1;
 
