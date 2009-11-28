package Template::TT3::Hub;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Base Badger::Hub',
    modules   => ':hub',                # import XXX_MODULE from T::Modules
    alias     => {
        # attach() and detach() don't do anything (at present), but they
        # establish a protocol for multiple front-end modules sharing a hub
        attach => \&self,
        detach => \&self,
    };


# The $COMPONENTS hash declares the methods that can be generated on demand to 
# load and instantiate various sub-components.  e.g. templates() creates and 
# returns a Template::TT3::Templates object (defined as the TEMPLATES_MODULE
# constant in in Template::TT3::Modules and imported via the 'modules' hook)

our $COMPONENTS = { 
    filesystem => FILESYSTEM_MODULE,
    templates  => TEMPLATES_MODULE,
    providers  => PROVIDERS_MODULE,
    plugins    => PLUGINS_MODULE,
    dialects   => DIALECTS_MODULE,
    cache      => CACHE_MODULE,
    store      => STORE_MODULE,
};


# The $DELEGATES hash declares methods that can be generated on demand to 
# delegate to an object returned by another method.  For example, the 
# C<< template => 'templates' >> entry specifies that the template() method 
# should delegate to the object returned by the templates() method.  So a 
# call to $hub->template() is the same as $hub->templates->template()

our $DELEGATES  = {
    template   => 'templates',
    provider   => 'providers',
    plugin     => 'plugins',
    dialect    => 'dialects',
};


sub self {
    $_[0];
}


sub destroy {
    my $self = shift;
    $self->debug("destroying hub() $self") if DEBUG;

    # nothing to do yet
}


sub DESTROY {
    $_[0]->debug("DESTROY $_[0]") if DEBUG;
    shift->destroy;
}


1;
