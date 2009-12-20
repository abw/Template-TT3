package Template::TT3::Element::String;

use Template::TT3::Class::Element
    version   => 2.69,
    base      => 'Template::TT3::Element::Literal',
    view      => 'string',
    constant  => {
        SOURCE_FORMAT => '"%s"',
    },
    alias     => {
        value          => \&text,
        values         => \&text,
        parse_filename => \&parse_expr,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;
    
    # copy original TEXT into EXPR in case we don't already have a 
    # reduced form (i.e. without quotes)
    $self->[EXPR] = $self->[TOKEN]
        unless defined $self->[EXPR];
    
    # strings can be followed by postops (postfix and infix operators)
    return $$token->next_skip_ws($token)
        ->parse_infix($self, $token, $scope, $prec);
}


sub text {
    $_[SELF]->[EXPR];
}


sub filename {
    $_[SELF]->text( $_[CONTEXT] );
}


sub template {
    my $self = shift;
    return $self->fetch_template(
        $self->text(@_), @_
    );
}


sub variable {
    $_[CONTEXT]->use_var( 
        $_[SELF], 
        $_[SELF]->text( $_[CONTEXT] )
    );
}


1;


__END__

=head1 NAME

Template:TT3::Element::String - base class element representing strings

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> to
represent quoted text strings. It acts as a common base class for the 
L<Template::TT3::Element::Squote> and
L<Template::TT3::Element::Dquote> elements used to represent 'single' and
"double" quoted strings, respectively.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Text>, L<Template::TT3::Element::Literal>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

=head2 parse_expr($token,$scope,$precedence)

This method is called to parse a string as an expression.

=head2 parse_filename($token,$scope,$precedence)

This method is called to parse a string as a filename.  It is defined as
an alias to L<parse_expr()>.

=head2 text($context)

This method returns the content of the quote string (i.e. not including the
quote marks) stored in the C<EXPR> slot.  Subclasses may redefine this method
to perform additional processing of the string content (e.g. double quoted
strings which may have embedded variable references).

=head2 value($context)

An alias to the L<text()> method.

=head2 values($context)

An alias to the L<text()> method.

=head2 filename($context)

This method is a thin wrapper around the L<text()> method.  It is called 
when a quoted string is used as a filename.

=head2 template($context)

This method fetches the template from the the C<$context> object passed as 
an argument, using its own L<text()> value as the identifier.

=head2 variable()

This method returns the string content (as returned by the L<text()> method)
as a variable object.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_string()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_string()>
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

This module inherits methods from the L<Template::TT3::Element::Text>, L<Template::TT3::Element::Literal>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

It is itself the base class for the L<Template::TT3::Element::Padding> and
L<Template::TT3::Element::String> modules.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
