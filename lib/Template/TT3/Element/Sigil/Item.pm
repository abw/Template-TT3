package Template::TT3::Element::Sigil::Item;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil',
    constants => ':elements ARRAY FORCE',
    alias     => {
        # we always force scalar value() on our target, even when we're
        # being called as list values()
        values    => \&value,

        # TODO: do we need one for list_values and/or hash_values()?
    };


sub parse_dotop {
    my ($self, $token, $scope, $prec) = @_;

    # advance past sigil token
    $$token = $self->[NEXT];
    
    # fetch next expression using our ultra-high RHS precedence, along with
    # the FORCE argument to ensure that we get at least one token if we can
    $self->[EXPR] = $$token->parse_expr(
        $token, $scope, $self->[META]->[RPREC], FORCE
    )   || return $self->fail_missing( expression => $token );

    $self->debug("using $self->[EXPR] as dotop: $self\n") if DEBUG;
    
    # TODO: allow other () [] {} to follow
    #return $$token->parse_postfix($self, $token, $scope, $prec);
    
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


# NOTE: I considered change the parse_expr() / parse_variable() methods to return 
# the next variable expression directly so we can avoid these indirections.
# However, that's a path to FAIL because the '$' sigil should always force
# scalar context.  Admittedly it's only required for edge cases like @$foo()
# where you want to call foo() in a scalar context, $foo(), but then want
# to unpack the list reference returned by it.  If we remove the $ at parse
# time then we end up with @$foo() being @foo() resulting in foo() being 
# called in list context with no further unpacking being done.

sub text {
    $_[SELF]->debug('$item text(): ', $_[SELF]->source) if DEBUG;
    $_[SELF]->[EXPR]->text($_[CONTEXT]);
}


sub value {
    $_[SELF]->debug('$item value(): ', $_[SELF]->source) if DEBUG;
    $_[SELF]->[EXPR]->value($_[CONTEXT]);
}



1;

__END__

=head1 NAME

Template:TT3::Element::Sigil::Item - element representing the C<$> sigil

=head1 DESCRIPTION

Element for the scalar item sigil C<$>.  This is used to denote variables
where a filename, keyword, bareword, or other token would be expected.

For example, if you happen to have a variable called C<fill>, you wouldn't
normally be able to access it because it's a reserved keyword in TT3.  By 
adding a C<$> prefix, you're indicating that it's a variable you're after.

    [% $fill %]           # variable, not a keyword

The same rule applies for calling object methods or accessing elements in a 
hash array or list.  We would usually expect to find a bareword or number 
following a dot operator.  If the item on the left of the dot is an object
then the name on the right is that of a method.  If it's a hash reference
then the name on the right is that of an item in the hash array.  If it's a 
list then the number on the right is the index of a particular item in the 
list.  The name on the right can also be that of a virtual method for all
data types.

    [% iterator.first %]            # object method
    [% user.name %]                 # hash item
    [% list.0 %]                    # list reference
    
    [% user.keys %]                 # hash virtual method
    [% list.first %]                # list virtual method

If you put a C<$> in front of the item on the right then it will be treated
as a variable.  
    
    [% n = 0 %]
    [% list.$n %]                   # same as [% list.0 %]

    [% key = 'fullname' %]
    [% user.$key %]                 # same as [% user.fullname %]

The same rule applies in double quoted strings.  If it starts with a C<$>
then it's variable reference.

    [% "Hello $name" %]

The C<$> sigil can also be used to force scalar context on the expression
on its right.  Scalar context is the default in TT3 so it is rarely required.
I can only think of one (highly contrived) example where you might need to 
use it. 

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Sigil>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 text()

=head2 value()

=head2 values()

An alias to L<value()>.

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

