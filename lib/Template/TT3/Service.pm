package Template::TT3::Service;

use Template::TT3::Class
    version     => 2.70,
    debug       => 0,
    base        => 'Template::TT3::Base',
    config      => 'template services',
    mutators    => 'template',
    init_method => 'configure',
    utils       => 'params',
    constant    => {
        SERVE => 'serve',
    };


sub serve {
    shift->not_implemented('in service base class');
}


# TODO: change this to pipeline()

sub service {
    my ($self, $source) = @_;
    my $serve = $self->can(SERVE);
    return sub {
        $serve->($self, params(@_), $source);
    };
}


1;

__END__

=head1 NAME

Template::TT3::Service - base class template service module

=head1 DESCRIPTION

This module implements a base class for template service modules.
A service is responsible for modifying the generated output from a 
template in some way.  For example, adding a header, footer, etc.

=head1 CONFIGURATION OPTIONS

The base class service module defines one optional configuration item.

=head2 template

Most services are involved in processing an additional template, e.g. 
a header, footer, wrapper, etc.  This default option is provided for that
purpose.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Base> and L<Badger::Base> base class modules. 

=head2 decorate($env, $source)

This is a stub method in the base class that should be re-defined by 
service subclasses.  

=head2 service($source)

This method creates a service wrapper subroutine around the service. 

    my $service = $service->service;

A service subroutine expects two arguments.  The first is a reference to 
a hash array containing a service environment.  At a minimum this must define
a C<context> item which references a L<Template::TT3::Context> object.

    my $env = {
        context => $context         # Template::TT3::Context object
    };

The second item is a reference to another service. We can turn a template into
a service subroutine by calling its
L<service()|Template::TT3::Template/service()> method.

    my $source = $template->service;

Now we can run our service service, passing it the environment hash and
the source service that it should modify.

    my $output = $service->($env, $source);

Individual service services can be chained together into servicing 
pipelines.





=head2 etc...

=head1 INTERNAL METHODS

The following methods are defined for internal use.

TODO: This documentation is an auto-generated stub.

=head2 internal_method1()

=head2 internal_method2()

=head2 etc...

=head1 PACKAGE VARIABLES

This module defines the following package variables.

TODO: This documentation is an auto-generated stub.

=head2 $VAR1

=head2 $VAR2

=head2 etc...

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

