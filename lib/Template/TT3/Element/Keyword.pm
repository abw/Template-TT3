package Template::TT3::Element::Keyword;

use Template::TT3::Class::Element
    version    => 2.69,
    debug      => 0,
    base       => 'Template::TT3::Element::Literal',
    view       => 'keyword';


sub parse_word {
    # keywords downgrade themselves to simple words when used after a dot
    shift->become('word')->parse_word(@_);
}


sub parse_dotop {
    # keywords downgrade themselves to simple words when used after a dot
    shift->become('word')->parse_dotop(@_);
}


1;

__END__

=head1 NAME

Template:TT3::Element::Keyword - base class for keyword elements

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It acts as a
base class for all keyword elements.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_word()

This method is called when a keyword appears in a position where a non-keyword
word is expected.  It downgrades (re-blesses) the keyword element to a
L<word|Template::TT3::Element::Word> object and then calls its
L<parse_word()|Template::TT3::Element/parse_word()> method, inherited from
the L<Template::TT3::Element> base class.

In summary, if you ask a keyword to be a word then it silently becomes one.

=head2 parse_dotop($token)

This method is called when a keyword appears immediately after a dot operator.
It downgrades (re-blesses) the keyword element to a
L<word|Template::TT3::Element::Word> object and then calls its
L<parse_dotop()|Template::TT3::Element::Word/parse_dotop()> method.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_keyword()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_keyword()>
method.

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

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
