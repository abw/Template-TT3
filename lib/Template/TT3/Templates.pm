package Template::TT3::Templates;

use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Template::TT3::Base',
    import      => 'class',
    utils       => 'textlike md5_hex',
    constants   => 'ARRAY HASH DELIMITER',
    modules     => 'TEMPLATE_MODULE',
    hub_methods => 'dialect filesystem',
    mutators    => 'cache store',
    constant    => {
        TEXT    => 'text',
        FILE    => 'file',
        COLON   => ':',
    },
    config      => [
        'hub|class:HUB',
        'template_path|path|class:TEMPLATE_PATH',
        'template_providers|providers',
        'template_scheme|scheme|class:SCHEME|method:FILE',
        'template_module|class:TEMPLATE_MODULE|method:TEMPLATE_MODULE',
        'cache|class:CACHE',
        'store|class:STORE',
    ],
    messages    => {
        bad_path    => 'Invalid template path specified: %s',
        bad_dialect => 'Invalid template dialect specified: %s',
        not_found   => 'Template not found: %s',
    };



sub init {
    my ($self, $config) = @_;
    my $class = $self->class;

    $self->debug("init() ", $self->dump_hash($config), "\n") 
        if DEBUG;

    $self->{ config } = $config;

    $self->configure($config)
         ->init_hub($config)
         ->init_path($config)
         ->init_providers($config);

    # ask the hub to provide us with cache/store if they're undefined (but
    # not if they're zero - that means "No caching/storing")
    my $hub = $self->hub;
#   $self->{ cache } = $hub->cache unless defined $self->{ cache };
#   $self->{ store } = $hub->store unless defined $self->{ store };
    
    if (DEBUG) {
        $self->debug("using cache: $self->{ cache }") if $self->{ cache };
        $self->debug("using store: $self->{ store }") if $self->{ store };
    }

    # In addition to the memory cache provided by Template::TT3::Cache (which
    # saves us from having to re-compile templates unless they've changed)
    # we also maintain a lookup table which maps a template name to the 
    # specific file that provided it and the time that we should check it
    # again to see if it has changed (time now  + STAT_TTL seconds).  This 
    # saves us from making repeated stat() calls on a file (or reads from a 
    # database) in rapid succession when the chances of a file changing are
    # very slim.
    $self->{ lookup } = { };

    # load up the template module (quick hack to get things working)
    $self->debug("loading template module: $self->{ template_module }")
        if DEBUG;
        
    class( $self->{ template_module } )->load;

    return $self;
}


sub init_path {
    my $self    = shift; 
    my $config  = shift || $self->{ config };
    my $tpaths  = $config->{ template_path } || [ ];
    my $tconfig = $config->{ template } || $config;
    my (@paths, $path, $args);

    $self->debug("tpaths: $tpaths\n", $self->dump_data($tpaths)) if DEBUG;

#   I did consider preserving Badger::Filesystem file objects in the 
#   template_path, but I think that for now it's simpler to just let it
#   be squished to text and treated as a convenient way to get a path
#   $tpaths = [ ref $tpaths ? $tpaths : split(DELIMITER, $tpaths) ] 

    # Split template_path on whitespace if specified as a string.  It 
    $tpaths = [ split(DELIMITER, $tpaths) ] 
        unless ref $tpaths eq ARRAY;

    # The $tpaths list can contain single paths (e.g. '/path/to/file') which 
    # can be followed by an optional hash of options, e.g.
    #    ['/path/to/files']  ['/path/to/files' => { ...options .. }]
    # or it can contain hashes of options with the path inside, e.g.
    #    [ { path => '/path/to/file', ...options... } ]
    # or some combination of the two.  We munge them into a list of hash refs.

    $self->debug("init_path() with ", $self->dump_data($tpaths), "\n") 
        if DEBUG;
    
    while (@$tpaths) {
        $path = shift @$tpaths;

        if (ref $path eq HASH) {
            # got a hash
            $args = $path;
        }
        elsif (ref $path) {
            # got a non-hash ref: throw error for now, but consider things like sub refs / path generators
            return $self->error_msg( bad_path => $path );
        }
        elsif (@$tpaths && ref $tpaths->[0] eq HASH) {
            # got a non-ref item, and the next item is a hash
            $args = shift @$tpaths;
            $args->{ path } = $path;
        }
        else {
            # got a non-ref item, and the next item isn't a hash (or there isn't a next item)
            $args = { 
                path => $path,
            };
        }

        push(@paths, { %$tconfig, %$args } );   # quick hack for now
    }

    $self->{ template_path } = @paths
        ? \@paths
        : $self->default_path($config);

    $self->debug(
        "set template_path to ", 
        $self->dump_data($self->{ template_path })
    ) if DEBUG;
    
    return $self;
}


sub init_providers {
    my $self      = shift; 
    my $config    = shift || $self->{ config };
    my $tpaths    = shift || $self->{ template_path };
    my $default   = $self->{ template_scheme };         # 'file'
    my $pfactory  = $self->hub->providers;
    my $providers = $self->{ providers     } = [ ];
    my $ptype     = $self->{ provider_type } = { };
    my $pname     = $self->{ provider_name } = { };
    my (@providers, $provider, $chain, $item, $type, $name);
    
    $self->debug("init_providers() with ", $self->dump_list($tpaths), "\n") 
        if DEBUG;

    $self->destroy_providers;
    
    foreach $item (@$tpaths) {
        $self->debug("init_providers() for ", $self->dump_data($item))
            if DEBUG;
            
        $type = $item->{ type } ||= $item->{ scheme } || $default;
        $provider = $pfactory->provider( $type => $item );
        
        # add provider to the list of all providers
        push(@$providers, $provider);
        
        # also add it to the chain of providers for it's type and name
        $chain = $ptype->{ $type } ||= [ ];
        push(@$chain, $provider);
        
        if ($name = $item->{ name }) {
            $chain = $pname->{ $name } ||= [ ];
            push(@$chain, $provider);
        }
            
        $self->debug("$type provider => $provider")
            if DEBUG;
    }
    
    # TODO:
    #  * merge with the master config 
    #  * map prefix to provider

#    $self->todo;
    
    return $self;
}


sub template {
    my $self = shift;
    my $type = shift;
    my $name = shift;
    my $params;
    
    if ($type eq TEXT) {
        $params = {
            text => $name, 
            uri  => $self->text_uri($name),
        };
    }
    else {
        PROVIDER: foreach my $provider (@{ $self->{ providers } }) {
            $self->debug("asking provider $provider for template $name")
                if DEBUG;
                
            if ($params = $provider->fetch($name, @_)) {
                $params->{ uri } ||= $type.COLON.$name;
                last PROVIDER;
            }
            return $self->decline_msg( not_found => $name );
        }
    }
    
    $self->debug("template params: ", $self->dump_data($params))
        if DEBUG;
    
    return $self->{ template_module }->new($params);
        
#    $self->todo;
}


#sub dialects {
#    shift->hub->dialects(@_);
#}

sub default_path {
    return [
#        { path => shift->filesystem->root }
        { type => 'cwd' }
    ];
}

sub text_uri {
    my ($self, $text) = @_;
    return TEXT.COLON.md5_hex(ref $text ? $$text : $text);
}


sub destroy_providers {
    my $self = shift;
    return $self->{ template_providers }
        ? $self->todo
        : $self;
}


sub destroy {
    my $self = shift;

    $self->destroy_providers;

    # delete references to the cache/store that could be pointing back at us
    delete $self->{ cache };
    delete $self->{ store };
}

1;


__END__

sub init_dialects {
    my $self     = shift; 
    my $config   = shift || $self->{ config };
    my $dialects = $self->{ dialects };
    my $dialect  = $self->{ dialect };
    my $tclass   = $dialects->dialect($dialect)
        || return $self->error_msg( bad_dialect => $dialect );

    # store the default type name and start a hash to quickly map
    # template types to class names.
    $self->{ dialect_class } = {
        $dialect => $tclass,
    };
    
    return $self->{ dialects };
}

sub init_path {
    my $self   = shift; 
    my $config = shift || $self->{ config };
    my $inpath = $config->{ template_path }     # other modules use 'path' but
             ||= delete($config->{ path })      # 'template_path' is canonical
             ||  $self->pkgvar('TEMPLATE_PATH');
    my (@paths, $path, $args);
    
    $inpath = [ $inpath ] unless ref $inpath eq 'ARRAY';

    # The $inpath list can contain single paths (e.g. '/path/to/file') which 
    # can be followed by an optional hash of options, e.g.
    #    ['/path/to/files']  ['/path/to/files' => { ...options .. }]
    # or it can contain hashes of options with the path inside, e.g.
    #    [ { path => '/path/to/file', ...options... } ]
    # or some combination of the two.

    $self->debug("init_path() => ", $self->dump_list($inpath), "\n") if $DEBUG;
    
    while (@$inpath) {
        $path = shift @$inpath;

        if (ref $path eq 'HASH') {
            # got a hash
            $args = $path;
        }
        elsif (ref $path) {
            # got a non-hash ref: throw error for now, but consider things like sub refs / path generators
            return $self->error_msg( bad_path => $path );
        }
        elsif (@$inpath && ref $inpath->[0] eq 'HASH') {
            # got a non-ref item, and the next item is a hash
            $args = shift @$inpath;
            $args->{ path } = $path;
        }
        else {
            # got a non-ref item, and the next item isn't a hash (or there isn't a next item)
            $args = { 
                path => $path,
            };
        }

        push(@paths, $args->{ path });   # quick hack for now
        
        # TODO:
        #  * merge with the master config 
        #  * add default type
        #  * add file: prefix to paths (if no prefix defined)
        #  * map prefix to provider

        #  $self->not_implemented('config merging and path store');
    }
    $self->{ template_path } = \@paths;
    
    return $self;
}

sub dialect_class {
    my $self    = shift;
    my $dialect = shift || $self->{ dialect };
    return  $self->{ dialect_class }->{ $dialect }
        ||= $self->{ dialects }->dialect($dialect)
        ||  $self->error_msg( bad_dialect => $dialect );
}

# quick hack to get things working

sub template {
    my $self = shift;
    my $name = shift;
    my $args = @_ && ref $_[0] eq 'HASH' ? shift : { @_ };
    my $file = $self->locate($name)
        || return $self->decline_msg( not_found => $name );
    my $type = $self->dialect_class;
    my $text = UTILS->read_file($file);

    $self->debug("template $name located in $file\n") if $DEBUG;

    # TODO: make ref
    $args->{ text } = $text;

    # add back-reference from template to the templates collective
    $args->{ templates } ||= $self;
    
    $self->debug("creating new template: $type / $args\n") if $DEBUG;
    $type->new($args);
}

sub locate {
    my $self = shift;
    my $name = shift;
    my $path = $self->{ template_path };
#    local $Template::Utils::DEBUG = 1;

    # TODO: if no path is defined then we could try the name by itself.
    # This would make $t->template('/foo/bar') and $t->template('./foo/bar')
    # both work without having to define a default template path
    
    if ($path && @$path) {
        return UTILS->find_file($name, $path);
    }
    else {
        return -f $name ? $name : undef;
    }
}

# fetch
#   * perform any name mapping
#     - obj, ref, array, etc
#   * look for prefix type?
#   * look in cache
#   * search path
#   * get config   
#   * instantiate
#   * save in cache  

1;

__END__

=pod

# TODO / ISSUES

In the templates path we need to be able to differentiate between 
configuration items destined for the provider and those for the templates.

     path => [ 
        # template config params
        { path => '/here', type => 'TT3', ignore => '<# #>' }
        # providers config params
        { type => 'dbi', database => 'mysite', table => 'templates' }
     ] 

I think we probably need to enforce a 'template' prefix on those 
params destined for the template.

    { path => '/here', template_type => 'TT3', template_ignore => '<# #>' }

or put them in a 'template' item, like this:

    { path => '/here', template => { type => 'TT3', ignore => '<# #>' } }

Or we invert the problem and put the provider parameters in a particular
place:

    { path => '/here', type => 'TT3', ignore => '<# #>', provider => { ... } }

Different ways of specifying the provider.

    provider => 'file'
    provider => { type => 'file', path => '/here', option1 => 'blah', etc }
    provider_type => 'file'
    
Or we put both in:

    Template->new({
        template_path => [
            '/here' => {
                template => { type => 'TT3', ignore => '[# #]' },
                provider => { type => 'file', ignore => '.svn' },
                cache    => 1,
                store    => 1,
            },
            '/there' => {
                template => { type => 'TT2', PRE_CHOMP => 1, POST_CHOMP => 1 },
                provider => { type => 'file', ignore => '.CVS' },
                cache    => 1,
                store    => 0,
            },
        ],
    });

Yes, I think that's the cleanest solution.  In most cases the provider will not
be required.  'file' will be the default and other schemes like 'http' can be 
auto-detected.

    template_path => [ '/path/to/blah' ]         # file: is implicit
    template_path => [ 'file:/path/to/blah' ]    # file: is explicit
    template_path => [ 'http://templates.mydomain.com/public/templates' ]
    template_path => [ 'dbi:mysql:mysite' => { table => 'templates', key => 'path' } ]
    template_path => [ 'dbi:mysql:mysite?table=templates;key=path' ]    # er... not sure

However, it does mean that some of the simple cases get less simple:

    template_path => [
       '/here'  => { type => 'TT2' },
       '/there' => { type => 'TT3', ignore => '<# #>' },
    }

    template_path => [
       '/here'  => { template_type => 'TT2' },
       '/there' => { template => { type => 'TT3', ignore => '<# #>' } },
    }

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


#========================================================================
# Template::Templates
#
# DESCRIPTION
#   Templates manager responsible for fetching, loading, caching and 
#   storing templates.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
# TODO
#   * look at a better way of integrating the module factory behaviour
#     of Template::Types without having to define it as a separate 
#     module.
#========================================================================


