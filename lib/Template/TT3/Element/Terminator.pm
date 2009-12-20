package Template::TT3::Element::Terminator;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'terminator',
    alias     => {
        parse_expr  => 'null',
        parse_body  => 'null',
        parse_infix => 'reject',
        terminator  => 'next_skip_ws',      # TODO: don't need this?
    };

1;


__END__

=head1 NAME

Template:TT3::Element::Terminator - element for representing terminator tokens

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> to
represent various terminator tokens. It also acts as a base class for the 
L<Template::TT3::Element::End> module.

Terminators are used to deliberately break the flow of the expression parser.
For example, the C<end> token at the end of a template block is used to tell
the parse "Hey, stop that! We've run out of expressions. I'm special!".
Terminator tokens are also to indicate the end of data constructs such as
the C<]>, C<}> and C<)> tokens used for the end of list definitions, hash
definitions and parameter lists, respectively.  Again, they are used as 
hard markers to indicate the end of a sequence of expressions.  

Terminator tokens are usually only ever consumed by the corresponding token
that began a block. For example, the C<[> token indicates the start of a list.
The L<parse_expr()|Template::TT3::Element::Construct/parse_expr()> method for
that element calls the L<parse_body()|Template::TT3::Element/parse_body()>
method on the next token. This will consume expressions until the next
terminator token and then return the block of expressions parsed.  At this
point the C<$token> reference will be pointing at the unconsumed terminator 
token.  The method can check that the terminator token is correct (e.g. is
C<]> to match the opening C<[>) and raise a syntax error if that is not the
case.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_expr($token,$scope,$precedence)

This method returns C<undef> to indicate that a delimiter element does not 
yield an expression.

=head2 parse_body($token,$scope,$precedence)

This method returns C<undef> to indicate that a delimiter element does not 
yield a body of expressions.

=head2 parse_infix($lhs,$token,$scope,$precedence)

This method is an alias to the L<reject()|Template::TT3::Element/reject()>
method inherited from the L<Template::TT3::Element> base class.  It is called
by a preceding expression to give infix operators the opportunity to contribute
to expression generated.  Terminators are mean old gits that don't like to 
contribute anything, so they simply return the expression on the left of the
terminator, passed to the method as the C<$lhs> argument.

=head2 terminator()

An alias to the L<next_skip_ws()|Template::TT3::Element/next_skip_ws()>
method inherited from L<Template::TT3::Element>.

TODO: I don't think this is used any more.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_terminator()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_terminator()> method.

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

It is the base class for the L<Template::TT3::Element::End> module.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
