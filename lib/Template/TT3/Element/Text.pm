package Template::TT3::Element::Text;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    view      => 'text',
    constant  => {
        SOURCE_FORMAT => '"%s"',
    };


1;

__END__

=head1 NAME

Template:TT3::Element::Text - element representing text tokens

=head1 DESCRIPTION

This module implements a thin subclass of L<Template::TT3::Element> to
represent literal text tokens, i.e. blocks of plain text in a template. It
acts as a common base class for the L<Template::TT3::Element::Padding> and
L<Template::TT3::Element::String> element.

=head1 METHODS

This module inherits all methods from the L<Template::TT3::Element::Literal>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

=head1 CONSTANTS

The following constant method is defined:

=head2 SOURCE_FORMAT

This defines a C<sprintf()> format string of C<"%s"> (note that the quotes
are part of the format).  This is used by the
L<source()|Template::TT3::Element::Literal> method inherited from 
L<Template::TT3::Element::Literal> to render a canonical representation 
of the template source code for this element.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element::Literal>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

It is itself the base class for the L<Template::TT3::Element::Padding> and
L<Template::TT3::Element::String> modules.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
