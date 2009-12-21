package Template::TT3::Element::Eof;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'eof',
    constant  => {
        eof   => 1,
    },
    alias     => {
        parse_expr => 'null',
    };

1;

__END__

=head1 NAME

Template:TT3::Element::Eof - element representing the end of a template file

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Elemen> to represent the
end of file. An EOF token is automatically added to the end of the list of
tokens scanned by the L<Template::TT3::Scanner> module. The token essentially
ignores all methods called on it and refuses to advance the token pointer.
When parsing is complete, the C<$token> pointer should be reference an EOF
token. Otherwise we know that any tokens between the current token and the EOF
token have not been parsed and can report that fact accordingly.

The alternative to having an explicit EOF token is to simply leave the 
C<NEXT> reference of the final token undefined.  However, that means that
we must always check that the C<NEXT> slot is defined before attempting to 
call a method against it.

e.g.

    sub some_parsing_method {
        my $self = shift;
        $self->[NEXT]->parse_body(...);     # NEXT is always defined
    }

vs

    sub some_parsing_method {
        my $self = shift;
        $self->[NEXT] && $self->[NEXT]->parse_body(...);
    }

Using an explicit EOF token means that we know that the C<NEXT> slot is
I<always> defined for an element.  Except, of course, for the EOF token
which should I<never> have a C<NEXT> slot defined.  But then, the EOF token
never does anything, other than steadfastly refusing to do anything at all,
so it's not an issue.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Delimiter>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_expr()

Returns C<undef> to indicate that this element doesn't yield an expression.

=head2 eof()

This constant method returns C<1> to indicate that it is the end-of-file
token.  It replaces the default L<eof()|Template::TT3::Element/eof()> method
inherited from L<Template::TT3::Element> which returns C<0> indicating that
all the other elements aren't the end-of-file token.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_eof()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_eof()> method.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

The EOF element is constructed automatically by the L<Template::TT3::Scanner>
module as part of the L<tokenise()|Template::TT3::Scanner/tokenise()> method.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
