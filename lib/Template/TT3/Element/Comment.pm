package Template::TT3::Element::Comment;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Whitespace',
    view      => 'comment';

  
1;

__END__

=head1 NAME

Template:TT3::Element::Comment - element for representing ignorable comments

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Whitespace> to
represent ignorable comments.

=head1 METHODS

This module implements the following method in addition to those inherited
from the L<Template::TT3::Element::Whitespace>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_comment()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_comment()> method.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element::Whitespace>,
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
