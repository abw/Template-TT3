package Template::TT3::Element::Sigil::List;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil',
    constants => ':elements ARRAY SPACE',
    alias     => {
        pairs => \&values,
    };


sub text {
    $_[SELF]->debug('@list text(): ', $_[SELF]->source) if DEBUG;
    join(
        SPACE, 
        $_[SELF]->values($_[CONTEXT]) 
    );
}


sub value {
    $_[SELF]->debug('@list value(): ', $_[SELF]->source) if DEBUG;
    my @values = $_[SELF]->[EXPR]->list_values($_[CONTEXT]);

    # not sure if we should always return a list in scalar context?
    # e.g. should C<foo = @bar> be like C<(foo) = @bar> or C<foo = [@bar]>
    return @values > 1
        ? \@values
        :  @values;
}


sub values {
    $_[SELF]->debug('@list values(): ', $_[SELF]->source) if DEBUG;
    $_[SELF]->[EXPR]->list_values($_[CONTEXT]);
}


sub in_signature {
    my ($self, $name, $signature) = @_;
    my $sigil = $self->[TOKEN];
    $signature ||= { };

    # we can't be an argument in a function signature if we have args
    # or we have a dynamic name, e.g. $$foo
#    return $self->bad_signature( bad_arg => $name )
#        if $self->[ARGS] || $self->[EXPR];

    # fail if there's an existing list argument
    # FIXME: we should delegate to the expression - that must check args,
    # dynamic name, etc.
    my $token = $self->[EXPR]->[TOKEN];

    # check that there isn't already an argument with a '@' sigil - we 
    # can't have two
    return $self->bad_signature( dup_sigil => $name, $token, $sigil )
        if $signature->{ $sigil };

    # save (name => type) pair
    $signature->{ $sigil } = $token;
    $signature->{ $token } = $sigil;

    return $signature;
}


1;

__END__

=head1 NAME

Template:TT3::Element::Sigil::List - element representing the C<@> sigil

=head1 DESCRIPTION

Element for the list context sigil '@' which forces list context on 
function/methods calls and unpacks list references.

This module implements a subclass of L<Template::TT3::Element::Sigil>
for representing the list context sigil C<@>.

It is used to extract the value pairs of a list reference.

    [% foo = [1, 2, 3]
       bar = [4, 5, 6]
       baz = [@foo, @bar]       # same as: baz = [1, 2, 3, 4, 5, 6]
    %]

If its target expression is a function then it will be called in list 
context.

    [% bar()  %]                # called in scalar context by default
    [% @bar() %]                # called in explicit list context

It is also used in function signatures to indicate a list variable that
should collect all additional positional arguments.

    [% foo(@list) = "You called foo() with $list.join" %]
    [% foo(10,20,30) %]    # You called foo() with 10 20 30

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Sigil>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 text()

=head2 value()

=head2 values()

=head2 pairs()

An alias to L<values()>.

=head2 in_signature()

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
L<Template::TT3::Element::Sigil>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
