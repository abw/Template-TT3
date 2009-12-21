package Template::TT3::Element::Word;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    view      => 'word',
    roles     => 'pair';


sub parse_expr {
    # words become variables when requested as an expression
    shift->become('variable')->parse_expr(@_);
}


sub parse_dotop {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    $self->debug("using $self->[TOKEN] as dotop: $self\n") if DEBUG;
    return $self;
}


1;

__END__

=head1 NAME

Template:TT3::Element::Word - element representing bare words

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> for
representing bare words.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_expr()

This method is called when a word appears at the start of an expressions.
It upgrades (re-blesses) the word element to a
L<variable|Template::TT3::Element::Variable> object and then calls its
L<parse_expr()|Template::TT3::Element::Variable/parse_expr()> method.

In summary, if you ask a word to be an expression then it silently becomes a
variable expression.

=head2 parse_dotop($token)

This method is called when a word appears immediately after a dot operator.
It advances the element referenced by the C<$token> pointer and returns
C<$self> to indicate that it is a syntactically valid dot operation.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_word()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_word()>
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
