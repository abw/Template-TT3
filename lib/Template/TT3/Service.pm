package Template::TT3::Service;

use Template::TT3::Class
    version     => 2.70,
    debug       => 0,
    base        => 'Template::TT3::Base',
    config      => 'template services name!',
    accessors   => 'services',
    mutators    => 'name',
    init_method => 'configure',
    utils       => 'params',
    constant    => {
        SERVE => 'serve',
    },
    messages    => {
        no_source => 'No source pipeline specified to connect %s service to.',
    };


sub serve {
    shift->not_implemented('in service base class');
}


sub template_name {
    $_[0]->{ template };
}


sub template {
    my $self = shift;
    my $env  = shift || return $self->error_msg( missing => 'environment' );
    
    my $template = $env->{ $self->{ name } } 
                || $self->{ template }
                || return;

    return $env->{ context }->any_template( $template );
}


sub connect {
    my $self   = shift;
    my $source = shift || $self->no_source;
    my $serve  = $self->can(SERVE);

    return sub {
        $self->debug("pipeline segment invoked: $self->{ name }") if DEBUG;
        $serve->($self, params(@_), $source);
    };
}


sub no_source {
    my $self = shift;
    # Default behaviour is to raise an error message if no source pipeline
    # is specified to connect to.  Services that are sources (e.g. T~S~Input)
    # can re-define this to silently do nothing.
    return $self->error_msg( no_source => $self->{ name } );
}


sub hub {
    shift->services->hub;
}


1;

__END__

=head1 NAME

Template::TT3::Service - base class template service module

=head1 SYNOPSIS

    # an example of a service class
    package Template::TT3::Service::Header;
    
    use Template::TT3::Class
        version => 2.70,
        debug   => 0,
        base    => 'Template::TT3::Service',
        config  => 'name=header';
    
    sub serve {
        my ($self, $env, $pipeline) = @_;
        
        # fetch the header template if there is one
        my $header = $self->template( $env )
            || return $pipeline->( $env );
            
        # process the header and then the rest of the pipeline
        return $header->fill_in( $env->{ context } )
             . $pipeline->( $env );
    }
    
    1;

=head1 DESCRIPTION

This module implements a base class for template service modules. A service is
responsible for modifying the generated output from a template in some way.
For example, adding a header, footer, etc.

You should start by reading the documentation for L<Template::TT3::Services>
which provides an overview of services and service pipeline.

=head1 CONFIGURATION OPTIONS

The base class service module defines one optional configuration item.

=head2 template

Many services are involved in processing an additional template, e.g. 
a header, footer, wrapper, etc.  This default option is provided for that
purpose.  Subclasses may ignore this option if it is of no relevance and/or
define their own.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Base> and L<Badger::Base> base class modules. 

=head2 serve(\%env, $pipeline)

This is a stub method in the base class that should be re-defined by 
service subclasses.  

=head2 connect($pipeline)

This method creates a service pipeline subroutine around the service. 

    my $pipeline = $service->connect;

See L<Template::TT3::Services> for further details.

=head2 template_name()

Returns the name of the default template specified via the L<template> option.

=head2 template(\%env)

Returns a template object for the default template specified via the
L<template> option.  It is fetched from the L<context|Template::TT3::Context>
that must be provided in the environment passed to the method.

=head1 INTERNAL METHODS

=head2 no_source()

This method is called by the L<connect()> method when called without a 
source C<$pipeline> to connect to.  In most cases this is an indication
of incorrect usage and the method throws an error accordingly.  However,
some services (most notably L<Template::TT3::Service::Input>) do not 
require a source pipeline as they usually sit at the start of a pipeline.
In this case the module will re-define the C<no_source()> method to silently
return without complaint.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Base> and
L<Badger::Base> base classes.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

