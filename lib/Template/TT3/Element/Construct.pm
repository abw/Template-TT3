package Template::TT3::Element::Construct;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elements';


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # advance past opening token
    $self->accept($token);

    # parse expressions.  Any precedence (0), allow empty lists (1)
    $self->[EXPR] = $$token->parse_block($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );
    
    # check next token matches our FINISH token
    return $self->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH );
    
    # advance past finish token
    $$token = $$token->next;

    # list/hash constructs can be followed by postops 
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub variable {
    $_[CONTEXT]->use_var( 
        $_[SELF] => $_[SELF]->value($_[CONTEXT]) 
    );
}


sub sexpr {
    my $self = shift;
    $self->[EXPR]->sexpr(
        shift || $self->SEXPR_FORMAT
    );
}


sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT, 
        $self->[EXPR]->source(@_)
    );
}



1;

__END__

=head1 NAME

Template:TT3::Element::Construct - base class element for grouping constructs

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It acts as a
common base class for the L<Template::TT3::Element::Construct::List>,
L<Template::TT3::Element::Construct::Hash>, 
L<Template::TT3::Element::Construct::Parens> and 
L<Template::TT3::Element::Construct::Args> modules. 

    [% a = [10, 20]    %]           # list construct
    [% a = { b=10 }    %]           # hash construct
    [% a = (b + c) * d %]           # parens
    [% foo(a, b, c=d)  %]           # args

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_expr()

=head2 variable()

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
L<Template::TT3::Element::Construct::List>, 
L<Template::TT3::Element::Construct::Hash>,
L<Template::TT3::Element::Construct::Parens>,
L<Template::TT3::Element::Construct::Args>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
