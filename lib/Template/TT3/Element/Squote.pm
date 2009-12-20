package Template::TT3::Element::Squote;

use Template::TT3::Class::Element
    version => 2.69,
    base    => 'Template::TT3::Element::String',
    view    => 'squote',
    constant => {
        SOURCE_FORMAT => "'%s'",
    };


1;

__END__

=head1 NAME

Template:TT3::Element::Squote - element representing single quoted strings

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::String> to
represent 'single quoted' text strings.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::String>,
L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_squote()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_squote()>
method.

=head1 CONSTANTS

The following constant method is defined:

=head2 SOURCE_FORMAT

This defines a C<sprintf()> format string of C<'%s'> (note that the quotes
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

This module inherits methods from the L<Template::TT3::Element::String>,
L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

