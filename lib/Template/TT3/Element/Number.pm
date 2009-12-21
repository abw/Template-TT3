package Template::TT3::Element::Number;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    view      => 'number',
    alias     => {
#       parse_number => 'self',        # this is already a number op
#       parse_dotop  => 'advance',
        number       => 'value',       # our token contains the number
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance token
    $$token = $self->[NEXT];
    
    # numbers can be followed by infix operators, e.g. 400 + 20
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


1;

__END__

=head1 NAME

Template:TT3::Element::Number - element representing number tokens

=head1 DESCRIPTION

This module implements a thin subclass of L<Template::TT3::Element::Literal>
to represent numbers.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_expr($token, $scope, $precedence)

This method is called when a number element appears at the start of an 
expression.  It advances the element referenced by the C<$token> pointer
and then calls the L<parse_infix()|Template::TT3::Element/parse_infix()>
method on the next non-whitespace token.

=head2 number()

An alias to the L<value()|Template::TT3::Element::Literal/value()> method
inherited from L<Template::TT3::Element::Literal>.

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
