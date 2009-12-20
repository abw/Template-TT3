package Template::TT3::Element::Whitespace;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'whitespace',
    alias     => {
        skip_ws => 'next_skip_ws',
    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    shift->next_skip_ws( $_[0] )
         ->skip_delimiter( @_ );
}


sub parse_expr {
    # we can always skip whitespace to get to an expression
    shift->next_skip_ws( $_[0] )
         ->parse_expr( @_ );
}


sub parse_body {
    # same for a block
    shift->next_skip_ws( $_[0] )
         ->parse_body( @_ );
}


sub parse_pair {
    # ditto pair
    shift->next_skip_ws( $_[0] )
         ->parse_pair( @_ );
}

1;

__END__

=head1 NAME

Template:TT3::Element::Whitespace - base class element for ignorable whitespace

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> to
represent ignorable whitespace. It acts as a base class for the 
L<Template::TT3::Element::Comment> and L<Template::TT3::Element::TagStart> 
element modules, among others.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 skip_ws($token)

An alias to the L<next_skip_ws()|Template::TT3::Element/next_skip_ws()>
method inherited from the L<Template::TT3::Element> base class.

=head2 skip_delimiter($token)

This skips the C<$token> pointer ahead to the next token following any 
whitespace and/or delimiters.

=head2 parse_expr($token,$scope,$precedence)

This method skips over the whitespace token and any subsequent whitespace 
tokens, then calls C<parse_expr()> on the next token.  In effect, if you 
call C<parse_expr()> on a whitespace token, it will automatically skip over
the whitespace and return the next expression if there is one.

=head2 parse_body($token,$scope,$precedence)

Like L<parse_expr()>, this method skips over the whitespace token(s) and 
calls C<parse_body()> on the next token.

=head2 parse_pair($token,$scope,$precedence)

Like L<parse_body()> and L<parse_expr()>, this method skips over the
whitespace token(s) and calls C<parse_pair()> on the next token.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_whitespace()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_whitespace()> method.

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

It is itself the base class for the L<Template::TT3::Element::Comment> and
L<Template::TT3::Element::TagStart> modules.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
