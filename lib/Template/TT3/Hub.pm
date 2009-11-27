package Template::TT3::Hub;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Base Badger::Hub',
    import    => 'class',
    utils     => 'params',
    modules   => ':hub',
    constants => 'ARRAY HASH DEFAULT',
    alias     => {
        # attach() and detach() don't do anything (at present), but they
        # establish a protocol for multiple front-end modules sharing a hub
        attach => \&self,
        detach => \&self,
    };

our $COMPONENTS = { 
    # Define methods that can be generated on demand to load and instantiate 
    # various sub components.  e.g. templates() creates and returns a 
    # Template::TT3::Templates object (defined as the TEMPLATES_MODULE
    # constant in in Template::TT3::Modules)
    templates => TEMPLATES_MODULE,
    plugins   => PLUGINS_MODULE,
    dialects  => DIALECTS_MODULE,
};

our $DELEGATES  = {
    # Define methods that are simple delegates to other methods, including
    # component methods listed above.  The LHS method is delegated to the RHS.
    # e.g. $hub->template() method is delegated to $hub->templates->template() 
    template   => 'templates',
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
