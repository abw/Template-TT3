package Template::TT3::Element::End;

use Template::TT3::Class::Element
    version   => 2.69,
    base      => 'Template::TT3::Element::Terminator',
    view      => 'keyword';


1;

__END__

=head1 NAME

Template:TT3::Element::End - element representing the 'end' terminator keyword

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Terminator> to
represent the C<end> token.  The actual keyword used can be something else
(depending on the grammar), but the underlying concept is the same.  It
denotes the end of a sequence of expressions that comprise a template block.

=head1 METHODS

This module implements the following method in addition to those inherited
from the L<Template::TT3::Element::Terminator>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_keyword()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_keyword()> method.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element::Terminator>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

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

