package Template::TT3::Element::Squote;

use Template::TT3::Class::Element
    version => 2.69,
    base    => 'Template::TT3::Element::String',
    view    => 'squote';


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

The closely related L<Template::TT3::Class::Dquote> module implements an
element used to represent "double quoted" strings.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

