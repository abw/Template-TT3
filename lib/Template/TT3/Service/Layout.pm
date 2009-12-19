package Template::TT3::Service::Layout;

use Template::TT3::Class
    version => 2.70,
    debug   => 0,
    base    => 'Template::TT3::Service',
    config  => 'name=layout',
    utils   => 'params';


sub serve {
    my ($self, $env, $pipeline) = @_;

    # Render the pipeline content 
    my $content  = $pipeline->( $env );

    # See if a layout template is defined, if not then we're done
    my $layout   = $self->template( $env )
        || return $content;
    
    # Create a context with the content defined as a variable
    my $context  = $env->{ context }->with( content => $content );

    # Fetch the main page template
    my $template = $env->{ template }
        || return $self->error_msg( missing => 'input template' );

    # Have the context visit the main page template and then process 
    # the layout template.  This ensures that any slots in the layout
    # will be filled by blocks defined in the main page template
    $context->enter($template);
    
    my $result = $layout->try->fill_in( $context );

    $context->leave;
    
    return $@
        ? $self->throw($@)
        : $result;
}


1;

__END__

=head1 NAME

Template::TT3::Service::Layout - service module for adding a page layout

=head1 SYNOPSIS

    use Template3;
    
    my $tt3 = Template3->new(
        layout => 'site/layout.tt3',
    );
    
=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Service> for adding a page
layout to a template. A page layout is a template containing a reference to a
C<content> variable and/or any other C<slot> definitions that can be filled by
C<block>s in the input templates . The layout template is processed with the
C<content> variable set to a closure which renders the output from the
rest of the service pipeline.   The L<context|Template::TT3::Context> is 
set to be visiting the main template so that C<slot> definitions in the C<layout>
template can be filled from the main page template.

TODO: rewrite the above in plain English

=head1 CONFIGURATION OPTIONS

=head2 template

Used to specify the default template that should be used for a layout. It can
be specified as anything that the L<Template::TT3::Templates>
L<template()|Template::TT3::Templates/template()> method will accept, e.g. a
template name, text references, subroutine reference, etc.

C<template> is the default option for the service.  Thus the following:

    my $layout = Template::TT3::Services->service(
        layout => 'site/layout.tt3',
    );

is syntactic sugar for:

    my $layout = Template::TT3::Services->service(
        layout => {
            template => 'site/layout.tt3',
        },
    );

=head2 name

This can be used to change the name of the service component.  The default
name is C<layout>.  If a C<layout> is specified in the environment passed
to the pipeline service function then it will be used in preference to the 
default L<template>.

    $pipeline->(
        context => $context,
        input   => 'example.tt3',
        layout  => 'my/layout.tt3',     # over-ride default layout template
    );

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Service>, L<Template::TT3::Base> and L<Badger::Base>
base class modules.

=head2 serve(\%env, $pipeline)

This is the main service method.  It is called automatically when the 
service is bound in a pipeline that is executed.  A copy of the environment
is passed as the first argument (a reference to a hash array).  A reference
to a subroutine representing the rest of the pipeline is passed as the 
second argument.

The method looks in the environment for an item named C<layout>, or whatever
alternate L<name> the service has been given (e.g. C<site_layout>,
C<section_layout>, etc). If the item isn't specified then it instead uses the
default layout L<template> defined when the service is created. If that is
undefined or set to a false value (e.g. C<0> or the empty string C<''>) then
no layout is added. 

Rendering a layout template is a little complicated.  First we have to 
push the main page template onto the context's visit stack.  This is so 
that C<slot> definitions in the layout template can be filled by
C<block> definition in the main page template.  Then we define a closure
which renders the pipeline content and bind this to the C<content> variable.
Then we render the layout template.

TODO: tidy up the above.

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
