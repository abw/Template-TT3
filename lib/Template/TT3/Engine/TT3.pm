package Template::TT3::Engine::TT3;

use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Template::TT3::Engine',
    import      => 'class',
    modules     => 'HUB_MODULE',
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
    init_method => 'configure',
    mutators    => 'hub_module';

our $HUB_MODULE = HUB_MODULE;


#sub templates {
#    shift->hub->templates(@_);
#}


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

