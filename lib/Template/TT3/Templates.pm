package Template::TT3::Templates;

use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Template::TT3::Base',
    import      => 'class',
    utils       => 'textlike md5_hex is_object refaddr params self_params',
    constants   => ':types :from :scheme :lookup DELIMITER BLANK',
    modules     => 'TEMPLATE_MODULE',
    hub_methods => 'dialects dialect filesystem',
    mutators    => 'cache store',
    constant    => {
        TEXT      => 'text',
        DIALECT   => 'TT3',
        IO_HANDLE => 'IO::Handle',
    },
    config      => [
        'path|template_path|class:PATH',
        'providers|template_providers',
        'scheme|template_scheme|class:SCHEME|method:FILE_SCHEME',
        'dialect|class:DIALECT|method:DIALECT',
        'cache|class:CACHE',
        'store|class:STORE',
        'dynamic_path=0',
        'path_expires=1',
#       'hub|class:HUB',
#       'template_module|class:TEMPLATE_MODULE|method:TEMPLATE_MODULE',

    ],
    messages    => {
        bad_path    => 'Invalid template path specified: %s',
        bad_dialect => 'Invalid template dialect specified: %s',
        not_found   => 'Template not found: %s:%s',
        no          => 'No %s specified for template',
    };

use Badger::Timestamp 'TIMESTAMP';


sub init {
    my ($self, $config) = @_;
    my $class = $self->class;

    $self->debug("init() ", $self->dump_hash($config), "\n") 
        if DEBUG;

    $self->{ config } = $config;

    $self->configure($config)
         ->init_hub($config)
            # TODO: allow provider list to be pre-defined
         ->init_path($config)
         ->init_providers($config);

    # Ask the hub to provide us with cache/store if they're undefined (but
    # not if they're zero - that means "No caching/storing")
    my $hub = $self->hub;
    # disabled for now...
    $self->{ cache } = $hub->cache unless defined $self->{ cache };
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

    # Load up the template module (quick hack to get things working)
#    $self->debug("loading template module: $self->{ template_module }")
#        if DEBUG;
#        
#    class( $self->{ template_module } )->load;

    return $self;
}


sub init_path {
    my $self    = shift; 
    my $config  = shift || $self->{ config };
    my $tpaths  = $self->{ path } || [ ];
    my $tconfig = $config->{ template } || $config;
    my (@paths, $path, $args);

    $self->debug("tpaths: $tpaths\n", $self->dump_data($tpaths)) if DEBUG;

    # I did consider preserving Badger::Filesystem file objects in the path 
    # but I think that for now it's simpler to just let it be squished to text 
    # and treated as a convenient way to get a path.  We used todo this:
    #    $tpaths = [ ref $tpaths ? $tpaths : split(DELIMITER, $tpaths) ] 

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
        # pull one off (fnnarr)
        $path = shift @$tpaths;

        if (ref $path eq HASH) {
            # got a hash - that's a complete definition
            $args = $path;
        }
        elsif (ref $path) {
            # got a non-hash ref: throw error for now, but consider things 
            # like sub refs / path generators for the future
            return $self->error_msg( bad_path => $path );
        }
        elsif (@$tpaths && ref $tpaths->[0] eq HASH) {
            # got a non-ref item, and the next item is a hash so merge them
            $args = shift @$tpaths;
            $args->{ path } = $path;
        }
        else {
            # got a non-ref item, and the next item isn't a hash (or there 
            # isn't a next item), so it's a bare path.
            $args = { 
                path => $path,
            };
        }

        # merge the path-specific options with the general config 
        # TODO: check that this doesn't cause conflicts...
        push(@paths, { %$tconfig, %$args } );
    }

    $self->{ path } = @paths
        ? \@paths
        : $self->default_path($config);

    $self->debug(
        "set templates path to ", 
        $self->dump_data($self->{ path })
    ) if DEBUG;
    
    return $self;
}


sub init_providers {
    my $self      = shift; 
    my $config    = shift || $self->{ config };
    my $tpaths    = shift || $self->{ path   };

    # First clean up any existing providers
    $self->destroy_providers;

    # OK, you're good to go
    my $default   = $self->{ scheme        };         # 'file'
    my $providers = $self->{ providers     } = [ ];
    my $ptype     = $self->{ provider_type } = { name => $providers };
    my $pname     = $self->{ provider_name } = { };
    my $pfactory  = $self->hub->providers;
    my (@providers, $provider, $chain, $item, $type, $name);
    
    $self->debug(
        "init_providers() with ", 
        $self->dump_list($tpaths), 
        "\n"
    ) if DEBUG;

    # Build a provider for each item in the template path
    foreach $item (@$tpaths) {
        # TODO: Merge consecutive paths of the same type, so that 
        # ['foo', 'bar'] gets handled by a single provider 
        # (hmmm... maybe that's not such a good idea..)

        $self->debug("initialising provider: ", $self->dump_data($item))
            if DEBUG;

        # Create a provider for the specified (or default) type
        $type = $item->{ type } ||= $item->{ scheme } || $default;
        $provider = $pfactory->provider( $type => $item );
        
        # Add provider to the list of all providers
        push(@$providers, $provider);
        
        # Also add it to the chain of providers for it's type...
        $chain = $ptype->{ $type } ||= [ ];
        push(@$chain, $provider);
        
        # ...and name, if it has one
        if ($name = $item->{ name }) {
            $chain = $pname->{ $name } ||= [ ];
            push(@$chain, $provider);
        }
            
        $self->debug("$type provider => $provider")
            if DEBUG;
    }

    $self->debug(
        "PROVIDERS: ", $self->dump_data($self->{ providers })
    ) if DEBUG;
    
    return $self;
}


#-----------------------------------------------------------------------
# Template methods.  template() dispatches to template_xxx() depending
# on the argument(s) specified.  This may trickle down through other
# template_xxx() methods culminating in a call to lookup(\%params)
#-----------------------------------------------------------------------

sub template {
    my $self = shift;
    my $src  = shift || return $self->error_msg( no => 'source' );
    my ($ref, $name, $params);

    if (is_object(TEMPLATE_MODULE, $src)) {
        # first argument is already a template object
        return $src;
    }
    elsif (ref $src) {
        return $self->template_ref($src, @_);
    }
    elsif (@_ && defined $_[0]) {
        return $self->template_type($src, @_);
    }
    else {
        return $self->template_name($src, @_);
    }
}


sub template_ref {
    my $self = shift;
    my $item = shift     || return $self->error_msg( no => 'reference' );
    my $ref  = ref $item || return $self->template( $item, @_ );
    my ($type, $name, $params);
    
    # some other kind of reference
    if ($ref eq SCALAR) {
        # a reference to some text
        return $self->template_text($item, @_);
    }
    elsif ($ref eq ARRAY) {
        # a reference to an array of arguments
        return $self->template(@$item, @_);
    }
    elsif ($ref eq HASH) {
        if (keys %$item == 1) {
            # a hash with exactly one entry, e.g. { file => 'blah.html' }
            return $self->template( (keys %$item)[0], (values %$item)[0], @_ );
        }
        else {
            # a hash with more (or possibly less) than one entry should
            # have 'type' and either a 'name' or a $type entry, 
            # e.g.{ type => 'file', name => 'foo.html' } 
            #  or { type => 'file', file => 'foo.html' }
            
            # TODO: we might have a block definition passed to use from a 
            # filename element that has resolved it locally
            $params = $item;
            $type   = $params->{ type } || $self->lookup($params); #return $self->error_msg( no => 'type' );
            $name   = $params->{ name } || $params->{ $type };
            return $self->template($type, $name, $params);
        }
    }
    elsif ($ref eq CODE) {
        # a code reference
        return $self->template_code($item, @_);
    }
    elsif ($ref eq GLOB) {
        return $self->template_glob($item, @_);
    }
    elsif (is_object(IO_HANDLE, $item)) {
        return $self->template_fh($item, @_);
    }
    else {
        # 
        return $self->error_msg( invalid => type => $type );
    }
}


sub template_text {
    my $self   = shift;
    my $text   = shift;
    my $params = params(@_);
    $params->{ name } ||= FROM_TEXT;
    $params->{ text }   = $text;
    $params->{ id   }   = $self->text_id($text);
    return $self->lookup($params);
}


sub template_code {
    my $self   = shift;
    my $code   = shift;
    my $params = params(@_);
    $params->{ name } ||= FROM_CODE;
    $params->{ code }   = $code;
    $params->{ id   }   = $self->code_id($code);
    return $self->lookup($params);
}


sub template_glob {
    my $self   = shift;
    my $glob   = shift;
    my $params = params(@_);
    $params->{ name } ||= FROM_FH;
    $params->{ text }   = $self->hub->input_glob($glob);
    $params->{ id   }   = $self->text_id( $params->{ text } );
    return $self->lookup($params);
}


sub template_fh {
    my $self   = shift;
    my $fh     = shift;
    my $params = params(@_);
    $params->{ name } ||= FROM_FH;
    $params->{ text }   = $self->hub->input_fh($fh);
    $params->{ id   }   = $self->text_id( $params->{ text } );
    return $self->lookup($params);
}


sub template_name {
    shift->template_type( NAME_SCHEME, @_ );
}


sub template_type {
    my $self   = shift;
    my $type   = shift;
    return $self->template_text(@_) if $type eq TEXT_SCHEME;
    my $name   = shift;
    my $params = params(@_);
    my $uri    = $type.COLON.$name;
    my ($lookup, $id, $template);

    $params->{ name } ||= $name;
    $params->{ type }   = $type;
    $params->{ uri  }   = $uri;

    # See if we've previously mapped this type:name uri to a template.  If 
    # we have then $self->{ lookup } will contain an entry telling us the 
    # definitive id for the template.  We can then use that to look in the 
    # cache(s) to see if we've got it in memory or on disk.  Otherwise we 
    # have to go through the usual route of asking all the providers for it.

    ID_LOOKUP: {
        # a dynamic template_path defeats any path lookup caching
        last ID_LOOKUP
            if $self->{ dynamic_path };

        # see if we've looked up an item with this name before
        last ID_LOOKUP
            unless $lookup = $self->{ lookup }->{ $uri };
    
        # delete and ignore lookup entry if it's gone stale
        if (time > $lookup->[LOOKUP_EXPIRES]) {
            $self->debug("$uri lookup data has expired\n") if DEBUG;
            $self->debug("expired at $lookup->[LOOKUP_EXPIRES], time is now ", time);
            delete $self->{ lookup }->{ $uri };
            last ID_LOOKUP;                                 # STALE PATH
        }
            
        # if the lookup failed then it'll fail again so we can bail early
        unless ($id = $lookup->[LOOKUP_ID]) {
            $self->debug("$uri was previously not found\n") if DEBUG;
            return $self->not_found($type, $name, $params); # NOT FOUND 
        }
            
        # we've got a candidate for caching
        if ($template = $self->cached($id)) {               # TODO: modified?
            $self->debug("found cached version of $name\n") if DEBUG;
            return $template;                               # FOUND
        }
        else {
            $self->debug("$uri ($id) has expired from the cache\n") if DEBUG;
            delete $self->{ lookup }->{ $uri };
        }
    }
    
    return $self->locate($params);
}



#-----------------------------------------------------------------------
# Lookup methods
#-----------------------------------------------------------------------

sub lookup {
    my ($self, $params) = self_params(@_);
    my $id = $params->{ id };

    # lookup in the cache or go straight to template preparation
    return $id
        && $self->cached($id)
        || $self->prepare($params);
}


sub locate {
    my ($self, $params) = self_params(@_);
    my $found;

    my $type = $params->{ type } 
        || return $self->error_msg( missing => 'type' );
        
    my $name = $params->{ name } 
        || return $self->error_msg( missing => 'name' );
        
    my $provs = $self->{ provider_type }->{ $type } 
        || return $self->error_msg( invalid => type => $type );

    $self->debug("asking ", scalar(@$provs), " provider(s) for $type:$name")
        if DEBUG;

    # Ask each provider in turn
    PROVIDER: {
        foreach my $provider (@$provs) {
            $self->debug("asking provider $provider for template $type:$name")
                if DEBUG;
            
            # Yo!  Provider!  Wazzup?
            if ($found = $provider->fetch($name, @_)) {
                $self->debug("provider found it: ", $self->dump_data($found))
                    if DEBUG;
                $params = {
                    provider => $provider,
                    %$params,
                    %$found,
                };
                last PROVIDER;
            }
        }
        # Nobody loves me. Everybody hates me. Think I'll go eat worms...
        return $self->not_found( $type, $name, $params );
    }
    
    my $id = $params->{ id };

    return $id
        && $self->cached($id)
        || $self->prepare($params);
}


#-----------------------------------------------------------------------
# preparation and caching methods
#-----------------------------------------------------------------------

*cached = \&cache_fetch;

sub cache_fetch {
    my ($self, $id, $modified) = @_;
    my $data;

    # see if the named template is in the cache
    if ($self->{ cache } && ($data = $self->{ cache }->get($id))) {
        $self->debug("$id found in the cache => $data\n") if DEBUG;
        return $data;
            # create/update LOOKUP entry for faster path matching
#            $self->add_lookup_path($data);
    }

    if ($self->{ store } && ($data = $self->{ store }->get($id))) {
        $self->debug("$id found in the store\n") if DEBUG;
        return $data;
    }
    
    return undef;
}


sub cache_store {
    my ($self, $id, $data) = @_;
    my $cached;

    if ($self->{ cache }) {
        $self->debug("storing $id in memory cache as $data\n") if DEBUG;
        $self->{ cache }->set($id, $data);
        $cached = $id;
    }
    
    # add to store - this needs refactoring along with Template::TT2::Document
    if ($self->{ store }) {
        shift->todo('persistent template storage');
    }
    
    return $cached;
}


sub prepare {
    my ($self, $params) = self_params(@_);
    my $dialect;
    
    $self->debug("template params: ", $self->dump_data($params))
        if DEBUG;
    
    # The provider can tell us what dialect it thinks the template is (e.g.
    # by looking at a file extension, consulting a database or lookup table,
    # or if the dialect is pre-defined for a particular provider).  Otherwise
    # we use the default dialect.
    $dialect = $params->{ dialect }
           ||=   $self->{ dialect };

    # fetch a dialect object for the dialect name
    $dialect = $self->{ dialects }->{ $dialect }
           ||= $self->dialect($dialect);
           # check that dialect() throws an error or catch decline

    # create back-reference to us and the hub so that templates can talk 
    # back to us and/or reach other parts of the framework
    $params->{ templates } = $self;
    $params->{ hub       } = $self->{ hub };

    # finally have the dialect create us a template
    return $self->prepared(
        $params,
        $dialect->template($params)
    );
}


sub prepared {
    my ($self, $params, $template) = @_;
    my $id  = $params->{ id  };
    my $uri = $params->{ uri };
    
    # If we've got an id then we can store it in the cache.  If it is
    # successfully cached and we have a uri (e.g. file:foo.tt3) then 
    # we can create a lookup entry so that we can quickly map file:foo.tt3
    # to the cache entry indexed by $id
    
    if ($id && $self->cache_store($id, $template, $params)) {
        # a dynamic path defaults any path lookup caching
        if ($uri && ! $self->{ dynamic_path }) {
            $self->debug("adding lookup entry for [$uri => $id] expiring in $self->{ path_expires } seconds")
                if DEBUG;
            $self->{ lookup }->{ $uri } = [
                $id, time + $self->{ path_expires }
            ];
        }
    }
    
    return $template;
}



#-----------------------------------------------------------------------
# Methods for generating ids for template that don't already have a uri
# (e.g. file path).  Templates read from text get a unique (for practical 
# purposes) uri based on an MD5 hex string, e.g. text:1a2b3c4da5e6f7e8d.
# Templates that are wrappers around code refs get code:1234567 using 
# their refaddr.
#-----------------------------------------------------------------------

sub text_id {
    my ($self, $text) = @_;
    return TEXT_SCHEME.COLON.md5_hex(ref $text ? $$text : $text);
}


sub code_id {
    my ($self, $code) = @_;
    # generate a unique (for practical purposes) uri for text-based templates
    # based on an MD5 hex string, e.g. text:1a2b3c4da5e6f7e8d
    return CODE_SCHEME.COLON.refaddr($code);
}


sub not_found {
    shift->decline_msg( not_found => @_ );
}


sub default_path {
    # The default template_path is the current working dir
    return [
        { type => 'cwd' }
    ];
}


sub destroy_providers {
    my $self = shift;
    
    return $self->{ providers }
        ? $self->todo
        : $self;
}


sub destroy {
    my $self = shift;

    # I'll fetch my coat...
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


