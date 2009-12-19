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
        text        => \&token,
        value       => \&token,
        values      => \&token,
    };


sub token {
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

This module implements a subclass of L<Template::TT3::Element>. It acts as a
common base class for the L<Template::TT3::Element::Word>,
L<Template::TT3::Element::Keyword> and L<Template::TT3::Element::Keyword>
modules.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_word()

This method is an alias to the L<advance()|Template::TT3::Element/advance()>
method inherited from the L<Template::TT3::Element> base class.

=head2 text()

This method is an alias to the L<token()|Template::TT3::Element/token()>
method inherited from the L<Template::TT3::Element> base class.  It simply
returns the literal token text.

=head2 value()

An alias as per L<text()>.

=head2 values()

An alias as per L<text()>.

=head2 name()

An alias as per L<text()>.

TODO: I've taken this out... I don't think we're using name() any more...
let's see what breaks.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>,
L<Template::TT3::Base>,
L<Template::TT3::Element>,
L<Template::TT3::Element::Word>, 
L<Template::TT3::Element::Keyword>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
