package Template::TT3::Element::Operator::Assign;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::InfixRight
                  Template::TT3::Element::Operator::Assignment
                  Template::TT3::Element',
    import    => 'class',
    as        => 'pair',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT => '<assign:<%s><%s>>', 
    },
    alias     => {
        as_pair => 'self',          # I can do pairs, me
        number  => \&value,         # FIXME
        values  => \&value,         # TODO: parallel assignment
    };

use constant {
    ARITY      => RHS + 1,
    LHS_METHOD => RHS + 2,
    RHS_METHOD => RHS + 3,
};


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher or equal precedence can bind tighter
#    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
#        || return $self->fail_missing( expression => $token );

    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
        || return $self->fail_missing( expression => $token );
    
#    $self->debug("assign LHS signature: ", $lhs->hparse_signature) if DEBUG;

    # Call the lvalue to set our LHS and RHS for us.  This allows the lvalue
    # to create a lazy (subroutine) wrapper around the RHS if it has a 
    # function signature like [% bold(text) = "<b>$text</b>" %]
    my $assign = $lhs->as_lvalue($self, $scope);

    # TODO: negotiation between the LHS and RHS to work out what kind of
    # assignment this is.  Is the LHS has parens, e.g. foo(), then it's a 
    # "lazy" assignment (e.g. create a subroutine).  If the LHS is a list
    # term (e.g. (foo, bar) or @baz) then we need to treat the RHS different
#   push(@$self, $lhs->assignment($rhs));
    
    # at this point the next token might be a lower or equal precedence 
    # operator, so we give it a chance to continue with the current operator
    # as the LHS
    return $$token->skip_ws->parse_infix($assign, $token, $scope, $prec);
}


sub value {
    $_[SELF]->debug("assign value(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->[LHS]
            ->variable( $_[CONTEXT] )        # fetch LHS as a variable
            ->set(                           # set it to RHS value
                $_[SELF]->[RHS]->value( $_[CONTEXT] )
              )->value($_[SELF]);

#    $_[SELF]->debug("assign value(): ", $_[SELF]->source) if DEBUG;
#    $_[SELF]->debug("about to fetch LHS variable: $_[SELF]->[LHS]");
#    my $var = $_[SELF]->[LHS]->variable( $_[CONTEXT] );
#    $_[SELF]->debug("got LHS value(): $var");
#    $_[SELF]->debug("RHS is $_[SELF]->[RHS]: ", $_[SELF]->[RHS]->source) if DEBUG;
#    my $result = $_[SELF]->[RHS]->value( $_[CONTEXT] );
#    $_[SELF]->debug("got RHS value(): $result");
#    $var->set( $result );
#    $_[SELF]->debug("set value");
#    
#    return $var->value;
}


sub pairs {
    $_[SELF]->debug("pairs [$_[SELF]->[LHS]] [$_[SELF]->[RHS]]") if DEBUG;
    return $_[SELF]->[LHS]->name( $_[CONTEXT] )     # fetch LHS as a name
        => $_[SELF]->[RHS]->value( $_[CONTEXT] );   # fetch RHS as a value
}


sub params {
    $_[3]->{ $_[SELF]->[LHS]->name( $_[CONTEXT] ) }
           = $_[SELF]->[RHS]->value( $_[CONTEXT] );
           
    # my ($self, $context, $posit, $named) = @_;
#    $named ||= { };
#    my $name  = $_[SELF]->[LHS]->name( $_[CONTEXT] );
#    my $value = $_[SELF]->[RHS]->value( $_[CONTEXT] );
#    $self->debug("adding named parameter: $name => $value") if DEBUG;
#    $named->{ $name } = $value;
}


1;

__END__

=head1 NAME

Template:TT3::Element::Operator::Assign - element representing assignments

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It is used
to represent assignments.

    [% a = b %]

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_infix()

=head2 number()

FIXME: This is currently an alias to the L<value()> method, but that bypasses
the numlike test that the element base class method provides.

=head2 value()

=head2 values()

An alias to L<value()>.

=head2 pairs()

=head2 params()

=head2 TODO

See if we can turn the InfixRight and Assigment base classes into mixin 
roles.

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
L<Template::TT3::Element::Operator::InfixRight>, 
L<Template::TT3::Element::Operator::Assignment>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


