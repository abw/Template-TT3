package Template::TT3::Service::Input;

use Template::TT3::Class
    version => 2.70,
    debug   => 0,
    base    => 'Template::TT3::Service',
    config  => 'name=input';


sub serve {
    my ($self, $env, $pipeline) = @_;

    my $input = $self->template( $env )
        || return $self->error_msg( missing => $self->{ name } );

    # TODO: not sure about this... but I think it's the best way to 
    # propogate the compiled template to other services, e.g. layout
    $env->{ template } = $input;
    
    # UPDATE: this needs to be extended.  We must have the template in 
    # context before we begin executing any pipeline components.  I think
    # our pipeline should instead be [input [template header footer etc] output]
    # but that makes me think that we're drifting away from the original
    # simplicity of the service pipeline.  When we need to start nesting 
    # them just to get the basics working then it suggests it's too simple
    # for common use.  For now we're going to force the 'template' into 
    # the context variable so I can test the META directive.
    $self->debug("setting template to $input in context: $env->{ context }")
        if DEBUG;
    
    $env->{ context }->set( template => $input );
    
    return $input->fill_in( $env->{ context } );
}


sub no_source {
    # It's OK if no source pipeline is specified for us to connect to 
    # because we're an input service so we generate a source.
    return undef;
}

1;


__END__

=head1 NAME

Template::TT3::Service::Input - service module for main template page

=head1 SYNOPSIS

    use Template3;
    
    print Template3->render( input => 'hello.tt3' );
    
=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Service>. It is the initial
service component added to the start of a template service pipeline by the
L<Template::TT3::Engine::TT3> module. It fetches the input template
(identified as the C<input> item in the environment and processes it.  The
output generated is returned.

=head1 CONFIGURATION OPTIONS

=head2 template

Used to specify the default template that should be used for input. It can
be specified as anything that the L<Template::TT3::Templates>
L<template()|Template::TT3::Templates/template()> method will accept, e.g. a
template name, text references, subroutine reference, etc.

C<template> is the default option for the service.  Thus the following:

    my $input = Template::TT3::Services->service(
        input => 'greeting.tt3',
    );

is syntactic sugar for:

    my $input = Template::TT3::Services->service(
        input => {
            template => 'greeting.tt3',
        },
    );

In most cases the C<input> won't be specified as a configuration option, but
provided as an environment parameter passed to the
L<render()|Template3/render()> method (implemented by
L<Template::TT3::Engine::TT3>).

    use Template3;
    
    print Template->render(
        input => 'greeting.tt3'
    );

=head2 name

This can be used to change the name of the service component.  The default
name is C<input>.  If an C<input> is specified in the environment passed
to the pipeline service function then it will be used in preference to the 
default L<template>.

    $pipeline->(
        context => $context,
        input   => 'example.tt3',
    );

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Service>, L<Template::TT3::Base> and L<Badger::Base>
base class modules.

=head2 serve(\%env)

This is the main service method. It is called automatically when the service
is bound in a pipeline that is executed. A copy of the environment is passed
as the first argument (a reference to a hash array). 

The method looks in the environment for an item named C<input>, or whatever
alternate L<name> the service has been given.  It then fetches the template,
processes it and returns the output generated.

=head2 no_source()

This service component is an input source and expects to be connected at
the start of a pipeline.  Other components expect a reference to the source 
component that precedes it and will throw an error via the C<no_source()>
method if one isn't provided.

This module re-defines the C<no_source()> method to silently return C<undef>.
This allows it to be used at the start of a service pipeline.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Service>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

Services are loaded and instantiated by the L<Template::TT3::Services> factory
module. This is accessible via the L<Template::TT3::Hub> module. The
L<Template::TT3::Engine::TT3> module uses the services module to construct a
template processing pipeline.

Other similar services include L<Template::TT3::Service::Header>, 
L<Template::TT3::Service::Footer>, L<Template::TT3::Service::Layout>, 
L<Template::TT3::Service::Before> and L<Template::TT3::Service::After>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
