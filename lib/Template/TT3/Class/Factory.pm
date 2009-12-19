package Template::TT3::Class::Factory;

use Template::TT3::Class
    version   => 2.69,
    debug     => 0,
    uber      => 'Badger::Factory::Class',
    constant  => {
        FACTORY => 'Template::TT3::Factory',
    };

1;

__END__

=head1 NAME

Template::TT3::Class::Factory - class constructor for factory modules 

=head1 SYNOPSIS

    # This module is used internally to create factory modules responsible 
    # for loading other modules.  e.g. Template::TT3::Engines.
    
    package Template::TT3::Engines;
    
    use Template::TT3::Class::Factory
        version   => 3.00,
        debug     => 0,
        item      => 'engine',
        path      => 'Template(X)::(TT3::|)Engine';
    
=head1 DESCRIPTION

This module is a very thin subclass of the L<Badger::Factory::Class>
module.  It is used to construct other TT3 factory modules that are
responsible for loading other modules. For example, the
L<Template::TT3::Engines> modules is a factory module for loading
C<Template::TT3::Engine::*> modules.  

=head1 METHODS

This module implements the following constant methods in addition to those 
inherited from the L<Badger::Factory::Class>, L<Badger::Class> and 
L<Badger::Exporter> base classes.

=head2 FACTORY

This defines the base class factory for all TT3 modules to be 
L<Template::TT3::Factory>.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Base>,
L<Badger::Factory>, and L<Badger::Base> base classes.

It is itself the base class for L<Template::TT3::Engines>,
L<Template::TT3::Dialects>, L<Template::TT3::Providers>, and various other
factory modules.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


