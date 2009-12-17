package Template::TT3::Service::Header;

use Template::TT3::Class
    version => 2.70,
    debug   => 0,
    base    => 'Template::TT3::Service',
    config  => 'name=header';


sub serve {
    my ($self, $env, $pipeline) = @_;

    my $header = $self->template( $env )
        || return $pipeline->( $env );

    # TODO: should we run the pipeline first?
    return $header->fill_in( $env->{ context } )
         . $pipeline->( $env );
}


1;

__END__

=head1 NAME

Template::TT3::Service::Header - service module for adding a page header

=head1 SYNOPSIS

    use Template3;
    
    my $tt3 = Template3->new(
        header => 'site/header.tt3',
    );
    
=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Service> for adding a page 
header to a processed template.

=head1 CONFIGURATION OPTIONS

=head2 template

Used to specify the default template that should be used for a header. It can
be specified as anything that the L<Template::TT3::Templates>
L<template()|Template::TT3::Templates/template()> method will accept, e.g. a
template name, text references, subroutine reference, etc.

C<template> is the default option for the service.  Thus the following:

    my $header = Template::TT3::Services->service(
        header => 'site/header.tt3',
    );

is syntactic sugar for:

    my $header = Template::TT3::Services->service(
        header => {
            template => 'site/header.tt3',
        },
    );

=head2 name

This can be used to change the name of the service component.  The default
name is C<header>.  If a C<header> is specified in the environment passed
to the pipeline service function then it will be used in preference to the 
default L<template>.

    $pipeline->(
        context => $context,
        input   => 'example.tt3',
        header  => 'my/header.tt3',     # over-ride default header template
    );

If you want to have several different header services in the same pipeline
then you should give them unique names. For example, you might set one to
C<site_header> and the other to C<section_header>.  This allows you to 
change the name of either independently.

    $pipeline->(
        context        => $context,
        input          => 'example.tt3',
        site_header    => 'site/header.tt3',
        section_header => 'section/products/header.tt3',
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

The method looks in the environment for an item named C<header>, or whatever
alternate L<name> the service has been given (e.g. C<site_header>,
C<section_header>, etc). If the item isn't specified then it instead uses the
default header L<template> defined when the service is created. If that is
undefined or set to a false value (e.g. C<0> or the empty string C<''>) then
no header is added. 

Otherwise it processes the header template and then executes the C<$pipeline>
function to render the rest of the service pipeline. It returns the output
generated from the header concatenated with that returned by the C<$pipeline>
function. If no header is specified then it returns only the output from the
C<$pipeline> function.

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

Other similar services include L<Template::TT3::Service::Footer>, 
L<Template::TT3::Service::Wrapper>, L<Template::TT3::Service::Layout>, 
L<Template::TT3::Service::Before> and L<Template::TT3::Service::After>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
