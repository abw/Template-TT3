package Template::TT3::Service::Wrapper;

use Template::TT3::Class
    version => 2.70,
    debug   => 0,
    base    => 'Template::TT3::Service',
    config  => 'name=wrapper';


sub serve {
    my ($self, $env, $pipeline) = @_;

    my $wrapper = $self->template( $env )
        || return $pipeline->( $env );

    return $wrapper->fill_in(
        $env->{ context }->with( 
            content => $pipeline->( $env ) 
        )
    );
}


1;

__END__

=head1 NAME

Template::TT3::Service::Wrapper - service module for adding a page wrapper

=head1 SYNOPSIS

    use Template3;
    
    my $tt3 = Template3->new(
        wrapper => 'site/wrapper.tt3',
    );
    
=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Service> for adding a page 
wrapper to a processed template.  A page wrapper is a template containing
a reference to a C<content> variable.  The wrapper template is processed
with the C<content> variable set to contain the output from the rest of
the service pipeline (e.g. the output generated from the main template plus
any other header, footers, etc., added by other services).

=head1 CONFIGURATION OPTIONS

=head2 template

Used to specify the default template that should be used for a wrapper. It can
be specified as anything that the L<Template::TT3::Templates>
L<template()|Template::TT3::Templates/template()> method will accept, e.g. a
template name, text references, subroutine reference, etc.

C<template> is the default option for the service.  Thus the following:

    my $wrapper = Template::TT3::Services->service(
        wrapper => 'site/wrapper.tt3',
    );

is syntactic sugar for:

    my $wrapper = Template::TT3::Services->service(
        wrapper => {
            template => 'site/wrapper.tt3',
        },
    );

=head2 name

This can be used to change the name of the service component.  The default
name is C<wrapper>.  If a C<wrapper> is specified in the environment passed
to the pipeline service function then it will be used in preference to the 
default L<template>.

    $pipeline->(
        context => $context,
        input   => 'example.tt3',
        wrapper => 'my/wrapper.tt3',     # over-ride default wrapper template
    );

If you want to have several different wrapper services in the same pipeline
then you should give them unique names. For example, you might set one to
C<site_wrapper> and the other to C<section_wrapper>.  This allows you to 
change the name of either independently.

    $pipeline->(
        context         => $context,
        input           => 'example.tt3',
        site_wrapper    => 'site/wrapper.tt3',
        section_wrapper => 'section/products/wrapper.tt3',
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

The method looks in the environment for an item named C<wrapper>, or whatever
alternate L<name> the service has been given (e.g. C<site_wrapper>,
C<section_wrapper>, etc). If the item isn't specified then it instead uses the
default wrapper L<template> defined when the service is created. If that is
undefined or set to a false value (e.g. C<0> or the empty string C<''>) then
no wrapper is added. 

Otherwise it executes the C<$pipeline> function to render the rest of the
service pipeline. It then processes the wrapper template with the C<content>
variable set to contain the output from the C<$pipeline> function. It then
returns the output generated. If no wrapper template is specified then it
returns only the output from the C<$pipeline> function.

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
