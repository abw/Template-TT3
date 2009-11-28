package Template::TT3::Engine;

use Template::TT3::Class
    version   => 2.718,
    debug     => 0,
    base      => 'Template::TT3::Base Badger::Prototype',
    messages  => {
        not_implemented => '%s is not implemented in the base class template engine.',
    };


sub template {
    my $self = shift;
    return $self->templates->template( @_ )
        || $self->error( $self->templates->reason );
}


sub templates {
    shift->not_implemented;
}


1;

__END__

=head1 NAME

Template:TT3::Engine - base class for template processing engines

=head1 DESCRIPTION

This module implements a base class for template processing engines.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Base>, L<Badger::Base> and L<Badger::Prototype> base
classes.

=head2 process()

Stub method for subclasses to implement.  In the base class this throws 
a C<not implemented> error if called.

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
L<Template::TT3::Engines>,
L<Template::TT3::Engine::TT3>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
