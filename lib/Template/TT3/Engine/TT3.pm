package Template::TT3::Engine::TT3;

use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Template::TT3::Engine',
    import      => 'class',
    modules     => 'HUB_MODULE',
    words       => 'SERVICE',
    utils       => 'params',
    constants   => ':service ARRAY HASH DELIMITER DEFAULT BLANK',
    constant    => {
        TT3     => __PACKAGE__,
    },
    exports     => {
        any     => 'TT3',
    },
    config      => [
        'hub_module|class:HUB_MODULE', # can't add "|method:HUB_MODULE here...
    ],
    hub_methods => 'templates',
    auto_can    => 'hub_can',          # ...because the auto_can gets it
#   init_method => 'configure',
    mutators    => 'hub_module';

our $HUB_MODULE = HUB_MODULE;
our $SERVICE    = 'layout header footer wrapper';


#-----------------------------------------------------------------------
# initialisation methods
#-----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->configure($config);
    
    my $service = $config->{ service }
        || $self->class->any_var(SERVICE);

    my $services = $self->class->hash_vars( 
        SERVICES => $config->{ services } 
    );
    
    # tricky this... either of the SERVICE or SERVICES could have come
    # from a package variable far, far, away, and we can't reliably tell
    # which should take precedence: an existing $services->{ default } 
    # entry or a new $service.... Hmmm... for now we'll assume that an 
    # existing $services->{ default } wins because we don't define one of
    # those by default.
    $services->{ default } ||= $service;
    
    $self->{ services } = $services;
    $self->{ config   } = $config;

    $self->debug("services: ", $self->dump_data($services))
        if DEBUG;
    
    return $self;
}


#-----------------------------------------------------------------------
# Hub methods
#-----------------------------------------------------------------------

sub hub {
    my $self = shift->prototype;

    return @_
        ? $self->attach_hub(@_)
        : $self->{ hub }
      ||= $self->create_hub;
}


sub hub_can {
    my ($self, $name) = @_;

    $self->debug("hub_can() is seeing if the hub can $name()");
    
    # See if the hub can do the method requested
    my $method = $self->hub->can($name) || return;
    
    # Construct a new engine method to call the hub method.  We return 
    # it and the auto_can handler (see Badger::Class::Methods) takes care
    # of installing it into our class as a new method.  It's AUTOLOAD on dope.
    return sub {
        shift->hub->$method(@_);
    }
}


sub create_hub {
    my $self = shift;
    my $hmod = $self->{ hub_module };

    $self->debug(
        "creating hub ($hmod) with ", 
        $self->dump_data($self->{ config })
    ) if DEBUG;
    
    return (
        $self->{ my_hub } 
            = class( $hmod )
                ->load
                ->instance( $self->{ config } )
    );
}


sub destroy_hub {
    my $self = shift->prototype;
    my $hub  = delete( $self->{ my_hub } ) || return;

    $self->debug("destroy_hub() destroying $hub") if DEBUG;
    $hub->destroy;
}


sub attach_hub {
    my $self = shift->prototype;
    my $hub  = shift || return $self->error_msg( missing => 'hub' );
    
    # out with the old...
    $self->detach_hub;
    
    # ...and in with the new
    $self->{ hub } = $hub->attach($self);
}


sub detach_hub {
    my $self = shift->prototype;
    my $hub  = delete( $self->{ hub } ) || return;
    
    $self->debug("detach_hub() detaching from $hub") if DEBUG;
    $hub->detach($self);

    # explicitly destroy the hub if we created it
    $self->destroy_hub if $self->{ my_hub };
}


#-----------------------------------------------------------------------
# Template processing methods
#-----------------------------------------------------------------------

sub process {
    my $self    = shift;
    my $input   = shift;
    my $data    = @_ ? (ref $_[0] eq HASH ? shift : params(splice(@_))) : { };
    my $output  = shift || $self->{ output };
    my $options = @_ ? params(@_) : undef;
    return $self->render(
        input   => $input,
        data    => $data,
        output  => $output,
        options => $options,
    );
#    return $self->hub->output(
#        $template->fill($data),
#        @_
#    );
}

sub render {
    my $self = shift;
    my $env  = params(@_);
    $env->{ context } ||= $self->context->with( $env->{ data } );
    $self->service( $env->{ service } )->($env);
}
    

sub context {
    shift->hub->context;
}


sub service {
    my $self = shift;
    my $name = shift || DEFAULT;

    return $self->{ service }->{ $name }
       ||= $self->build_service($name);
}


sub build_service {
    my $self     = shift;
    my $name     = shift || DEFAULT;
    my $config   = $self->{ config };
    my $services = $self->{ services };
    my $service  = $services->{ $name }
        || return $self->error_msg( invalid => service => $name );
    my ($key, $value, @services);

    # we allow a service ist to be specified as a whitespace delimited string 
    # because we're nice like that and can easily expand it
    $service = $services->{ $name } = [ split(DELIMITER, $service) ]
        unless ref $service eq ARRAY;
    
    $self->debug("constructing service pipeline: ", join(', ', @$service))
        if DEBUG;

    # we always have an input service
    push(@services, INPUT_SERVICE, BLANK);

    foreach (@$service) {
        $key = $_;   # perl alias
        if (ref $key) {
            # A reference is a self-contained service object or specification.
            $self->debug("service reference: $key") if DEBUG;
            push(@services, $key);
        }
        elsif ($key =~ s/^(\w+)://) {
            my $type = $1;
            $value = $config->{ $key } || { };
            $value = { template => $value } unless ref $value eq HASH;
            $value->{ type } = $type;
            $value->{ name } = $key;
            $self->debug("service shortcut: $type => ", $self->dump_data($value)) if DEBUG;
            push(@services, $type => $value);
        }
        elsif (defined ($value = $config->{ $key })) {
            # Otherwise it's a name (e.g. 'header') and we look for the 
            # corresponding value in the master configuration.  If there is
            # no value define then we skip the service.
            $self->debug("service data: $key => $value") if DEBUG;
            push(@services, $key => $value);
        }
    }

    # we always have an output service (or will do once I've written it)
    #push(@services, OUTPUT_SERVICE, BLANK);
    
    $self->debug("connecting services: ", $self->dump_data(\@services)) if DEBUG;

    return $self->hub->services->connect(@services);
}


sub DESTROY {
    $_[0]->debug("DESTROY $_[0]") if DEBUG;
    shift->detach_hub;
}


1;

__END__

        
    else {
        # return the existing hub, or connect up to one
        return $self->{ hub } ||= do {
            my $module = $self->class->any_var('HUB');
            $self->debug("Connecting to hub: $module\n") if DEBUG;
            class($module)->load;
            $module->new($self->{ config });
        };
    }


=head1 NAME

Template:TT3::Engine::TT3 - TT3 template processing engine

=head1 DESCRIPTION

This module implements a front-end template processing engine that interfaces
to version 3 of the Template Toolkit.  

=head1 METHODS

This module implements the following methods in addition to, or replacing
those inherited from the L<Template::TT3::Engine>, L<Template::TT3::Base>,
L<Badger::Base> and L<Badger::Prototype> base classes.

=head2 process()

TODO

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>,
L<Badger::Prototype>,
L<Template::TT3::Base>,
L<Template::TT3::Engine>,
L<Template::TT3::Engines>,
L<Template::TT3::Engine::TT2>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

