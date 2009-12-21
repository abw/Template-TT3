package Template::TT3::Element::Separator;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    view      => 'separator';


sub parse_expr {
    my ($self, $token, @args) = @_;
    $$token = $self->[NEXT] if $token;
    $self->[NEXT]->parse_expr($token, @args);
}


sub skip_separator {
    $_[SELF]->next_skip_ws( $_[CONTEXT] )
            ->skip_separator( $_[CONTEXT] );
}


sub skip_delimiter {
    $_[SELF]->next_skip_ws( $_[CONTEXT] )
            ->skip_delimiter( $_[CONTEXT] );
}


1;

__END__

=head1 NAME

Template:TT3::Element::Separator - element for representing expression separators

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> to
represent expression separators, e.g. commas. Separators are nearly always
optional.  You can put them in if it makes you happy, but TT3 will usually
work just fine without them.

    [10, 20, 30]            vs          [10 20 30]
    {a=>10, b=>20}          vs          {a=>10 b=>20}

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_expr($token,$scope,$precedence)

This method advances the element referenced by the C<$token> variable past
the current token and then calls C<parse_expr()> on the next token.

=head2 skip_separator($token)

This method advances the element referenced by the C<$token> variable past
the current token and any subsequent whitespace or separator tokens.

=head2 skip_delimiter($token)

This method advances the element referenced by the C<$token> variable past
the current token and any subsequent whitespace or delimiter tokens.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_separator()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_separator()> method.

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

It is the base class for the L<Template::TT3::Element::TagEnd> module.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
