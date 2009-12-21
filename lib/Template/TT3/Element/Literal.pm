package Template::TT3::Element::Literal;

use Template::TT3::Class::Element
    version  => 2.69,
    roles    => 'filename',
    base     => 'Template::TT3::Element',
    constant => {
        SOURCE_FORMAT => '%s',
    },
    alias    => {
        parse_expr  => 'advance',
        parse_word  => 'advance',
        name        => \&text,
        value       => \&text,
        values      => \&text,
    };


sub text {
    # TODO: find out why this breaks when we alias it to the base class
    # token() method
    $_[SELF]->[TOKEN];
}


sub variable {
    # literal values can be converted to a text variable in order to perform 
    # dotops or other stringy operations on it
    $_[CONTEXT]->use_var( 
        $_[SELF], $_[SELF]->text( $_[CONTEXT] ) 
    );
}


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[TOKEN]
    );
}


1;

__END__

=head1 NAME

Template:TT3::Element::Literal - base class element for literal elements

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> to represent
literal tokens. It acts as a common base class for the
L<Template::TT3::Element::Text>, L<Template::TT3::Element::Word>,
L<Template::TT3::Element::Keyword> and various other modules.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_word()

This method is an alias to the L<advance()|Template::TT3::Element/advance()>
method inherited from the L<Template::TT3::Element> base class.

=head2 parse_expr()

This method is an alias to the L<advance()|Template::TT3::Element/advance()>
method inherited from the L<Template::TT3::Element> base class.

=head2 text()

This method simply returns the literal token text.

=head2 value()

An alias to the L<text()> method.

=head2 values()

An alias to the L<text()> method.

=head2 variable()

Returns a L<Template::TT3::Variable> object to represent the text.  The 
variable object can be used to call dotop methods against the literal value.

=head2 source()

Returns a canonical representation of the template source expression for this
element. It uses the C<sprintf()> format returned by the L<SOURCE_FORMAT>
constant method to render the literal text. In this base class the
C<SOURCE_FORMAT> is defined to be C<%s>, resulting in a simple pass-through of
the token text. Subclasses may redefine C<SOURCE_FORMAT> to render a different
representation of the element.

=head1 CONSTANTS

This module defines the following constant.  Note that constants are 
implemented in Perl as subroutines that can be called as methods against
an object.  

    my $format = $self->SOURCE_FORMAT;

This allows a subclass to re-define the C<SOURCE_FORMAT> constant method to
return a different value.

=head2 SOURCE_FORMAT

This returns a C<sprintf()> string for the L<source()> method to use.  In
this base class it returns C<%s>.  Subclasses may redefine it to return a
different format.

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

It is itself the base class for the L<Template::TT3::Element::Text>,
L<Template::TT3::Element::Number>, L<Template::TT3::Element::Word>,
L<Template::TT3::Element::Keyword> and L<Template::TT3::Element::Filename>
modules.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
