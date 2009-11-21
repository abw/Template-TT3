package Template::TT3::Element::Sigil;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    constants => ':elements FORCE',
    constant  => {
        SEXPR_FORMAT  => "<%s:%s>",
        SOURCE_FORMAT => '%s%s',
    },
    alias     => {
        SIGIL => 'token',
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance past sigil token
    $$token = $self->[NEXT];
    
    # fetch next expression using our ultra-high RHS precedence, along with
    # the FORCE argument to ensure that we get at least one token if we can
    # TODO: this should be parse_variable() so that keywords are rejected
    $self->[EXPR] = $$token->parse_expr(
        $token, $scope, $self->[META]->[RPREC], FORCE
    )   || return $self->missing( expression => $token );
    
    # TODO: allow other () [] {} to follow
    #return $$token->parse_postfix($self, $token, $scope, $prec);
    
    return $$token->skip_ws->parse_postop($self, $token, $scope, $prec);
}


sub sexpr {
    my $self = shift;
    my $body = $self->[EXPR]->sexpr;
    $body =~ s/^/  /gsm;
    sprintf(
        $self->SEXPR_FORMAT,
        $self->SIGIL,
        "\n" . $body . "\n",
    )
}


sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT,
        $self->SIGIL,
        $self->[EXPR]->source
    );
}


1;

__END__

=head1 NAME

Template:TT3::Element::Sigil

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It acts as a
common base class for the L<Template::TT3::Element::Sigil::Item>,
L<Template::TT3::Element::Sigil::List> and
L<Template::TT3::Element::Sigil::Hash> modules which represent the
C<$>, C<@> and C<%> sigils respectively.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_expr()

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>,
L<Template::TT3::Base>,
L<Template::TT3::Element>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
