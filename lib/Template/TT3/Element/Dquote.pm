package Template::TT3::Element::Dquote;

use Template::TT3::Class::Element
    version => 2.69,
    debug   => 0,
    base    => 'Template::TT3::Element::String',
    view    => 'dquote',
    alias   => {
        value           => \&text,
        values          => \&text,
        parse_filename  => \&parse_expr,
    };


sub parse_expr {
    my ($self, $token, $scope) = @_;
    my $branch = $self->[BRANCH];
    
    $self->advance($token);

    if ($branch) {
        $self->[BLOCK] = $branch->parse_block(\$branch, $scope)
            || $self->fail_missing( branch => $branch );

        my $junk = $branch->remaining_text;
        return $self->error("Trailing text in double quoted string branch: $junk")
            if defined $junk && length $junk;
        
        $self->debug(
            "compiled double quoted string branch: ", 
            $self->[BLOCK]->source,
        ) if DEBUG;
    }

    return $$token->skip_ws($token)
        ->parse_infix($self, $token, $scope, $self->[META]->[LPREC]);
}


sub text {
    # If we have a BLOCK then this is a dynamic string, e.g. "foo $bar"
    # otherwise it's a static string in EXPR
    $_[SELF]->[BLOCK] 
        ? $_[SELF]->[BLOCK]->text($_[CONTEXT])
        : $_[SELF]->[EXPR]
}


1;

__END__

=head1 NAME

Template:TT3::Element::Dquote - element representing "double quoted" strings

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::String> to
represent "double quoted" text strings.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::String>,
L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_expr($token,$scope,$precedence)

This method is called to parse a string as an expression.

=head2 parse_filename($token,$scope,$precedence)

An alias to the L<parse_expr()> method.

=head2 text($context)

This method returns the content of the quoted string (i.e. not including the
quote marks) stored in the C<EXPR> slot.  If the string contains any 
variable expressions then they will be evaluated and inserted into the 
output text generated.

=head2 value($context)

An alias to the L<text()> method.

=head2 values($context)

An alias to the L<text()> method.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_dquote()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_dquote()>
method.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element::String>,
L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

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

