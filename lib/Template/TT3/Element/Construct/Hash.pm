package Template::TT3::Element::Construct::Hash;

use Template::TT3::Class 
    debug     => 0,
    base      => 'Template::TT3::Element::Construct',
    view      => 'hash',
    constants => ':elements',
    constant  => {
        FINISH        => '}',
        SOURCE_FORMAT => '{ %s }',
    },
    alias     => {
        values => \&value,
    };


sub parse_body {
    my ($self, $token, $scope, $parent, $follow) = @_;
    my (@exprs, $expr);
    
    $parent ||= $self;

    # skip past token any whitespace, then parse expressions
    my $block = $$token->next_skip_ws($token)->parse_block($token, $scope)
        || return $parent->fail_missing( $self->ARG_BLOCK, $token );

    # check next token matches our FINISH token
    return $parent->fail_missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH, $token );
    
    # if the parent defines any follow-on blocks (e.g. elsif/else for if)
    # then we look to see if the next token is one of them and activate it
    if ($follow && $$token->skip_ws($token)->in($follow)) {
        $self->debug("Found follow-on token: ", $$token->token) if DEBUG;
        return $$token->parse_follow($block, $token, $scope, $parent);
    }

    # return the $block we contain, not $self which is the { } container
    return $block;
}


sub text {
    shift->todo
}


sub value {
    $_[SELF]->debug("{hash} value(): ", $_[SELF]->source) if DEBUG;
    return {
        $_[SELF]->[EXPR]->pairs($_[CONTEXT])
    };
}


1;

__END__

=head1 NAME

Template:TT3::Element::Construct::Hash

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Construct>
for representing the list construct C<{ ... }>.

    [% foo = { a=10, b=20 } %]

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Construct>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_body()

=head2 text()

=head2 value()

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
L<Template::TT3::Element::Construct>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
