package Template::TT3::Element::Padding;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    view      => 'padding';


1;

__END__
    
=head1 NAME

Template:TT3::Element::Padding - element representing padding tokens

=head1 DESCRIPTION

This module implements a thin subclass of L<Template::TT3::Element::Literal>
to represent synthesised padding tokens (usually whitespace) that are inserted
into the parsed token stream as part of the parsing process.

For example, the C<=> pre and post chomp flags collapse any preceding or
following text to a single space. Consider the following example:

    foo    [%= 'bar' =%]    baz

The two blocks of four spaces surrounding the inline tag are added to the 
token stream as L<whitespace|Template::TT3::Element::Whitespace> tokens.
Whitespace tokens do not generate any output when the template is evaluated.
However, we keep them in the token stream in case we want to regenerate the
original template source (e.g. for debugging, error reporting, transforming
the template, etc).  At this point, the template would be rendered as if 
it was written:

    foo[% 'bar' %]baz

The C<=> chomp option creates C<Template::TT3::Element::Padding> elements
comprised of a single space.  These are injected into the token stream on
either side of the inline tag.  Padding elements I<do> yield their values
when the template is evaluated.  So the output generated from the template
is:

    foo bar baz

And all is good.

=head1 METHODS

This module implements the following method in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_padding()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_padding()>
method.

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

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

