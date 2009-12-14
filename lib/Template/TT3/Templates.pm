package Template::TT3::Templates;

use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Template::TT3::Base',
    import      => 'class',
    utils       => 'textlike md5_hex is_object refaddr params self_params',
    constants   => ':types :from :scheme :lookup_slots DELIMITER BLANK',
    modules     => 'TEMPLATE_MODULE IO_HANDLE',
    hub_methods => 'dialects dialect filesystem',
    filesystem  => 'File FILE',
    mutators    => 'cache store',
    constant    => {
        DIALECT => 'TT3',
    },
    config      => [
        'path|template_path|tpath|class:PATH',
        'providers|template_providers',
        'scheme|template_scheme|class:SCHEME|method:FILE_SCHEME',
        'dialect|class:DIALECT|method:DIALECT',
        'cache|class:CACHE',
        'store|class:STORE',
        'dynamic_path=0',
        'path_expires=1',
    ],
    messages    => {
        bad_path    => 'Invalid template path specified: %s',
        bad_dialect => 'Invalid template dialect specified: %s',
        not_found   => 'Template not found: <2>',
        no          => 'No %s specified for template',
    };


our $TYPES = {
    text   => \&template_text,
    code   => \&template_code,
    glob   => \&template_glob,
    handle => \&template_handle,
    fh     => \&template_handle,
};    



#-----------------------------------------------------------------------
# initialisation methods
#-----------------------------------------------------------------------

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
    # again to see if it has changed (time now  + path_expires seconds).  This 
    # saves us from making repeated stat() calls on a file (or reads from a 
    # database) in rapid succession when the chances of a file changing are
    # very slim.
    $self->{ lookup } = { };

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
# Template methods
#-----------------------------------------------------------------------

sub template {
    my $self = shift;
    my $src  = shift || return $self->error_msg( no => 'source' );
    my ($ref, $name, $params);

    if (ref $src) {
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

    if (is_object(TEMPLATE_MODULE, $item)) {
        # first argument is already a template object
        return $item;
    }
    elsif ($ref eq SCALAR) {
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
        return $self->template_handle($item, @_);
    }
    elsif (is_object(FILE, $item)) {
        return $self->template_file($item, @_);
    }
    else {
        # 
        return $self->error_msg( invalid => input => $item );
    }
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
    $params->{ name } ||= FROM_HANDLE;
    $params->{ text }   = $self->hub->input_glob($glob);
    $params->{ id   }   = $self->text_id( $params->{ text } );
    return $self->lookup($params);
}


sub template_handle {
    my $self   = shift;
    my $fh     = shift;
    my $params = params(@_);
    $params->{ name } ||= FROM_HANDLE;
    $params->{ text }   = $self->hub->input_handle($fh);
    $params->{ id   }   = $self->text_id( $params->{ text } );
    return $self->lookup($params);
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


sub template_file {
    my $self   = shift;
    my $file   = File(shift);
    my $params = params(@_);
    $params->{ name } ||= $file->name,
    $params->{ text }   = $file->text;
    $params->{ id   }   = FILE_SCHEME.COLON.$file->definitive;
    return $self->lookup($params);
}


sub template_name {
    shift->template_type( NAME_SCHEME, @_ );
}


sub template_type {
    my $self   = shift;
    my $type   = shift;
    my $deleg  = $TYPES->{ $type }; return $self->$deleg(@_) if $deleg;
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
        if (time > $lookup->[EXPIRES]) {
            $self->debug("$uri lookup data has expired\n") if DEBUG;
            $self->debug("expired at $lookup->[EXPIRES], time is now ", time);
            delete $self->{ lookup }->{ $uri };
            last ID_LOOKUP;                                 # STALE PATH
        }
            
        # if the lookup failed then it'll fail again so we can bail early
        unless ($id = $lookup->[ID]) {
            $self->debug("$uri was previously not found\n") if DEBUG;
            return $self->not_found($type, $name, $params); # NOT FOUND 
        }
            
        # we've got a candidate for caching
        if ($template = $self->cache_fetch($id)) {          # TODO: modified?
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
        && $self->cache_fetch($id)
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
        && $self->cache_fetch($id)
        || $self->prepare($params);
}


#-----------------------------------------------------------------------
# preparation and caching methods
#-----------------------------------------------------------------------

sub cache_fetch {
    my ($self, $id, $modified) = @_;
    my $data;

    # TODO: go back over Template::TT2::Templates to see what the purpose
    # of $modified is and if we still need it

    # see if the named template is in the cache...
    if ($self->{ cache } && ($data = $self->{ cache }->get($id))) {
        $self->debug("$id found in the cache => $data\n") if DEBUG;
        return $data;

        # create/update LOOKUP entry for faster path matching
        # $self->add_lookup_path($data);
    }

    # ...or in the secondary store
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
    
    # add to store - not working yet - need to figure out how
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

=head1 NAME

Template::TT3::Templates - template manager

=head1 SYNOPSIS

    use Template::TT3::Templates;
    
    my $templates = Template::TT3::Templates->new(
        template_path => '/path/to/templates',
    );
    my $template = $templates->template('example.tt3')
        || die $templates->reason;

=head1 DESCRIPTION

This module implements a template manager responsible for loading, preparing
and caching templates.  It is an internal component of the Template Toolkit
which is loaded and used automatically by the L<Template::TT3::Hub> module.

=head1 CONFIGURATION OPTIONS

=head2 template_path / path

This can be used to specify the location or locations of templates.  In the
simple case it can be specified as a single string denoting a file system
location.

    my $templates = Template::TT3::Templates->new(
        template_path => '/path/to/templates',
    );

Multiple locations can be specified using an array reference.

    my $templates = Template::TT3::Templates->new(
        template_path => [
            '/path/to/my/templates',
            '/path/to/your/templates',
        ],
    );

The C<template_path> option can also be specified using the shorter alias 
C<path>.

=head2 dialect

This can be used to define the default dialect for templates. The default
dialect is C<TT3> if not otherwise specified. You can set it to any module or
short name that is recognised by the L<Template::TT3::Dialects> factory
module.  For example, if you want to use the L<TT2|Template::TT3::Dialect::TT2>
dialect you would write:

    my $templates = Template::TT3::Templates->new(
        dialect => 'TT2',
    );

Note that this only specifies the I<default> dialect.  This may be over-ridden
by a different C<dialect> setting in the L<template_path>

    my $templates = Template::TT3::Templates->new(
        dialect       => 'TT2',
        template_path => [
            { path    => '/path/to/my/templates' },     # uses TT2 dialect
            { path    => '/path/to/your/templates',     # uses TT3 dialect
              dialect => 'TT3' 
            }
        ],
    );

=head2 cache

This can be used to provide an object suitable for caching compiled templates.
The default caching module is L<Template::TT3::Cache> but you can substitute
any L<Cache::Cache> module to work in its place.

=head2 store

This can be used to provide an object suitable for storing compiled templates
to disk or some other secondary storage medium.  The default store module is
L<Template::TT3::Store> but you can substitute any L<Cache::Cache> module to 
work in its place.

NOTE: The store isn't working as we don't yet have a view to generate Perl
code from compiled templates.  This needs some work.

=head2 dynamic_path

The C<Template::TT3::Templates> module performs some additional internal
caching to quickly map template paths to cached templates without going
through the rigamarole of check each location every time.  However, if your
C<template_path> can change from one request to the next then there is no
guarantee that the C<hello.tt3> template we fetched last time you asked for 
it is going to be the same C<hello.tt3> template that you get this time.

The C<dynamic_path> option can be set to any true value to indicate that the
L<template_path> can change at any time. This will bypass the fast path lookup
and ensure that the L<template_path> providers are queried each time.

=head2 path_expires

This option is used in conjunction with the lookup path cache described above
in L<dynamic_path>. Even with a static L<template_path> there is still the
possibility that the templates on disk can change. We want to avoid doing the
full filesystem check for every request so we cache template paths for a short
while (typically a few seconds) before checking again.  The C<path_expires>
option can be set to indicate how much time should elapse (in seconds) before
a full filesystem check is performed.

If your templates never change or change infrequently then you can set this
to an arbitrarily large number (e.g. 3600 to check one every hour).  If you're 
a developer using a persistent template processing environment (e.g. a mod_perl 
handler) and you're changing your templates often then you should set this to 
a small number (e.g. 1 second) so that you can reload your browser and see any 
changes straight away.

=head2 template_providers

In the usual case the L<template_path> is used internally to generate a list
of provider object responsible for locating and loading templates.  The 
C<template_providers> option can be specified to override this.  This is an
advanced option and you are expected to know what you are doing if you use 
it.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Base> and L<Badger::Base> base classes. 

=head2 template($type, $name)

This method locates loads and returns a template object.

If the first argument is a reference of any kind then the method delegates
to the L<template_ref()> method.

    $templates->template($ref);         # calling this...
    $templates->template_ref($ref);     # ...ends up calling this

If a single non-reference argument is specified then the method delegates
to the L<template_name()> method.

    $templates->template('foo');        # calling this...
    $templates->template_name('foo');   # ...ends up calling this

If more than one argument is specified then the method delegates to the
L<template_type()> method.

    $templates->template(               # calling this...
        text => 'Hello [% name %]' 
    );
    $templates->template_type(          # ...end up calling this
        text => 'Hello [% name %]'
    )

All arguments passed to the C<template()> method are forwarded to the 
appropriate delegate method.  The C<template()> method returns whatever
value its delegate method returns.

If the template cannot be found then the method returns C<undef>. A message
indicating why it declined can be retrieved via the
L<reason()|Badger::Base/reason()> method (inherited from L<Badger::Base>).

    my $template = $templates->fetch('missing.tt3')
        || die $templates->reason;          # Template not found: missing.tt3

All errors are thrown as exceptions.  For example, if the module find a file
but cannot open it, or if a template is found but it contains a syntax error,
then an exception will be raised.

Failing to find a template that was requested is I<not> considered to be an
error condition. Rather, it is part and parcel of correct operation for the
module. You ask if a template is available and the module replies "Yes, here
it is" (a template object is returned) or "No, it isn't" (C<undef> is returned).

=head2 template_ref($ref, $params)

This method returns a template object for the reference passed as the first
argument, C<$ref>.  It can be any of the following types:

=head3 Template::TT3::Template

If the item is already a reference to a L<Template::TT3::Template> object
(or subclass) then it is returned without further ado.

=head3 SCALAR

A template can be specified by reference to a scalar variable containing
the template text.  This is delegated to the L<template_text()> method.

=head2 ARRAY

A template can be specified by reference to an array containing further
arguments that specify the type and/or name of a template.

    $templates->template_ref([ file => 'example.tt3' ]);
    $templates->template_ref([ text => 'Hello [% name %]' ]);

In this case the method delegates back to the L<template()> method, expanding
the contents of the array onto the start of the parameter list.

=head2 HASH

A template can be specified by reference to a hash array.  If this contains
exactly one key/value pair then it is treated as a template type and 
identifier (e.g. file name, template text, etc).

    $templates->template_ref({ file => 'example.tt3' });
    $templates->template_ref({ text => 'Hello [% name %]' });

In this case the method delegates back to the L<template()> method, adding
the type (key) and identifier (value) to the start of the parameter list.

If the hash array contains more than one key/value pair then it is treated
as a complete parameter specification for a template and is forwarded to 
the L<lookup()> method.

=head2 CODE

A template can be specified by reference to a subroutine that generates
the template output.  This is delegated to the L<template_code()> method.

=head2 GLOB

A template can be specified by reference to a Perl GLOB (e.g. C<\*STDIN>,
C<\*DATA>) from which the template source can be read. This is delegated to 
the L<template_glob()> method.

=head2 IO::Handle

A template can be specified by reference to an L<IO::Handle> object (or
subclass) defining a file handle from which the template source can be read. 
This is delegated to the L<template_handle()> method.

=head2 template_code($code, $params)

This method prepares a template object from a code reference which implements
the output generating logic for a template.

    my $code = sub {
        my $context = shift;
        return "Hello " . $context->var('name')->value;
    }
    
    my $template = $templates->template_code($code);
    
    print $template->fill( name => 'World' );       # Hello World

=head2 template_glob($glob, $params)

This method prepares a template object from a Perl GLOB reference (e.g.
C<\*STDIN>, C<\*DATA>) from which the template source can be read.

    my $template = $templates->template_glob(\*DATA);
    
    print $template->fill( name => 'World' );       # Hello World
    
    __DATA__
    Hello [% name %]

=head2 template_handle($fh, $params)

This method prepares a template object from an I<IO::Handle> object (or
subclass) from which the template source can be read.

    use Badger::Filesystem 'File';
    
    my $filehandle = File('hello.tt3')->open;
    my $template   = $templates->template_handle($filehandle);
    
    print $template->fill( name => 'World' );       # Hello World

=head2 template_text($text, $params)

This method prepares a template object from a text string or reference to a 
text string.

    my $source   = 'Hello [% name %]';
    my $template = $templates->template_text($source);   # either
    my $template = $templates->template_text(\$source);  # or
    
    print $template->fill( name => 'World' );       # Hello World

=head2 template_name($name, $params)

This method prepares a template object from the name passed as an argument.
It looks through all locations in the L<template_path> until it finds a 
template matching the C<$name> specified.  It returns a template object or
C<undef> if the template cannot be found.

    my $template = $templates->template_name('hello.tt3')
        || die $templates->reason;      # e.g. Template not found: hello.tt3
    
    print $template->fill( name => 'World' );       # Hello World

=head2 template_type($type, $name, $params)

This method prepares a template object using the C<$type> and C<$name> 
passed as arguments.  If C<$type> is C<text>, C<code>, C<glob>, C<handle>
or C<fh> (an alias for C<handle>) then it delegates to L<template_text()>,
L<template_code()>, L<template_glob()> or L<template_handle()>, respectively.

    $template = $templates->template_type( text   => 'Hello [% name %]' );
    $template = $templates->template_type( code   => sub { ... } );
    $template = $templates->template_type( glob   => \*STDIN );
    $template = $templates->template_type( handle => $fh );
    $template = $templates->template_type( fh     => $fh );

Otherwise it queries each of the providers for the L<template_path> that
correspond to the specified C<$type>. In the usual case the type will be
C<file> and all filesystem-based providers will respond.

    my $template = $templates->template_type( file => 'hello.tt3' )
        || die $templates->reason;      # e.g. Template not found: hello.tt3
    
    print $template->fill( name => 'World' );       # Hello World

=head1 INTERNAL METHODS

=head2 init($config)

Initialisation method. In turn this calls L<init_path()> and
L<init_providers()>.

=head2 init_path($config)

Initialisation method used to prepare the L<template_path>.

=head2 init_providers($config)

Initialisation method used to create a template provider for each location
in the L<template_path>.  Template providers are implemented as subclasses
of L<Template::TT3::Provider>.  In the usual case these will be 
L<Template::TT3::Provider::File> objects for fetching templates from the 
file system.

Provider objects are loaded and instantiated by the
L<Template::TT3::Providers> factory module.

=head2 lookup($params)

This method is used internally by the L<template()> method and friends.
It accepts a list or reference to a hash array of named parameters that
define initialisation parameters for a template.  If an C<id> parameter
is specified then the method will call L<cache_fetch()> to see if a 
cached version of the compiled template is available.  Otherwise it will
call the L<prepare()> method to prepare it.

=head2 locate($params)

This method is used internally by the L<template_type()> method.  It 
queries the provider for each location in the L<template_path> to see if
it can provide the requested template.  If the C<type> parameter is 
defined then it will only queries those providers corresponding to that 
type.

=head2 cache_fetch($id)

This method checks to see if a cached version of a template is available.
The cache is implemented using a L<Template::TT3::Cache> object.  The 
L<Template::TT3::Store> module may also be used to provide persistent 
secondary storage for compiled templates.  However this is not operational
at the time of writing because we don't yet have the appropriate view to
convert compiled templates to Perl code.

The method returns a template object from the cache or C<undef> if none is
available.

=head2 cache_store($id,$template)

This method is used to store a compiled template in the in-memory cache and/or
secondary store.

=head2 prepare($params)

This method is used to prepare a new template object from a set of
configuration parameters.

=head2 prepared($params, $template)

This method is called after a new template object is prepared by the 
L<prepare()> method.  It takes care of updating the cache (via a call
to L<cache_store()>) and updating the internal path lookup table for 
optimising subsequent requests for the same template.

=head2 text_id($text)

This method creates a unique (for practical purposes) identifier from a 
text string.  It is comprised of the C<text:> prefix followed by an MD5 hash
of the text. 

=head2 code_id($code)

This method creates a unique (for practical purposes) identifier from a code
references. It is comprised of the C<code:> prefix
followed by the memory address of the code reference.

=head2 not_found($type, $name)

This method is used to report templates that cannot be found.  It creates a 
decline message and returns C<undef>.  The message can be retrieved via a 
call to the L<reason()|Badger::Base/reason()> method inherited from 
L<Badger::Base>.

    my $template = $templates->template('missing.tt3')
        || die $templates->reason;

=head2 default_path()

This method constructs a default L<template_path> for those times when
is hasn't been explicitly defined.  The default path contains a single 
L<Template::TT3::Provider::Cwd> provider object which serves templates from
the current working directory of the filesystem.

=head2 destroy_providers()

This method is used to explicitly cleanup the providers it is using at 
garbage collection time.

=head2 destroy()

This method is used to explicitly cleanup the object at garbage collection
time.

=head1 PACKAGE VARIABLES

This module defines the following package variables.

=head2 $TYPES

This is a lookup table mapping C<text>, C<code>, C<glob>, C<handle> and
C<fh> (an alias for C<handle>) to the L<template_text()>, L<template_code()>,
L<template_glob()> and L<template_handle()> methods respectively. 

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Base> and
L<Badger::Base> base classes.

It uses the L<Template::TT3::Providers> module to create template 
provider objects.

Templates are returned as L<Template::TT3::Template> objects.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
