package Template::TT3::Element::Construct::Parens;

use Template::TT3::Class 
    debug     => 0,
    base      => 'Template::TT3::Element::Construct',
    view      => 'parens',
    constants => ':elements',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<parens:%s>",
        SOURCE_FORMAT => '( %s )',
    };


sub as_postfix {
    shift->become('var_apply')->as_postfix(@_);
}


sub as_args {
    my ($self, $token, $scope) = @_;

    # advance past opening token
    $self->accept($token);

    # parse expressions, any precedence (0), allow empty blocks (1)
    $self->[EXPR] = $$token->as_exprs($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );

    # check next token matches our FINISH token
    return $self->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH, $token );
    
    return $self;
}


sub as_signature {
    my ($self, $token, $scope, $parent) = @_;
    my (@exprs, $expr);
    my $signature = { };

    $parent ||= $self;
    my $name = $parent->[TOKEN];
    $self->debug("sign name: $name  parent is $parent") if DEBUG;

    # advance past opening token
    $self->accept($token);
    
    while ($expr = $$token->skip_delimiter($token)
                          ->as_expr($token, $scope)) {
        push(@exprs, $expr->signature($name, $signature));
    }

    # check next token matches our FINISH token
    return $parent->missing( $self->FINISH, $token )
        unless $$token->is( $self->FINISH, $token );

    return $signature;
}


sub text {
    $_[SELF]->[EXPR]->text($_[CONTEXT])
}


sub value {
    my @values = $_[SELF]->[EXPR]->values($_[CONTEXT]);
    return @values > 1
        ? join('', @values)
        : $values[0];
}


sub values {
    return $_[SELF]->[EXPR]->values($_[CONTEXT]);
}


sub params {
    # This isn't being called in the right place.  Function application
    # stores args as raw block
    
    my ($self, $context) = @_;
    $self->error('params() method needs some work');
    
    my ($posit, $named) = shift->[EXPR]->params(@_);
    $self->debug("posit: $posit   named: $named");
    
    push(@$posit, $named) 
        if $named && %$named;
    return @$posit;
}

1;

__END__

=head1 NAME

Template:TT3::Element::Construct::Parens

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Construct>
for representing a parenthesised list of expressions C<( ... )>.

    [% foo = ((1 + 2) * 3) %]

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Construct>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 as_postfix()

=head2 as_args()

=head2 as_signature()

=head2 text()

=head2 value()

=head2 values()

=head2 params()

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
