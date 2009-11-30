package Template::TT3::Engine::TT2;

use Carp;
use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Template::TT3::Engine',
    import      => 'class CLASS',
    constant    => {
        # define a constant load() method that returns the delegate class name
        load    => 'Template::TT2',
    };
    
class(load)->maybe_load || croak << 'EOF';
Oh Noes!

The Template::TT2 module could not be loaded.

You need to install this before you can use the 'TT2' engine.

EOF

1;

__END__

=head1 NAME

Template:TT3::Engine::TT2 - TT2 template processing engine

=head1 DESCRIPTION

This module implements a thin wrapper around C<Template::TT2>.  It provides
a backwards-compatibility wrapper for TT2.

=head1 METHODS

This module implements the following method.

=head2 load()

The L<Template3> module calls this method to determine the name of the engine
class to instantiate. In the usual case, the C<load()> method simple returns
its own class name (e.g. C<Template::TT3::Engine::TT3-E<gt>load()> returns
C<Template::TT3::Engine::TT3>. In this case, the C<Template::TT3::Engine::TT2>
module is a wrapper to load the C<Template::TT3> module (or display a helpful
error message if it's not installed) and then delegate to it.  Accordingly,
the C<load()> method returns the constant value C<Template::TT2>.

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
L<Template::TT3::Engine::TT3>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

