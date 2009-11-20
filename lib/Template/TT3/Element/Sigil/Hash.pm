
#-----------------------------------------------------------------------
# Template:TT3::Element::Sigil::Hash
#
# Element for the hash context sigil '%' which forces hash context on 
# function/methods calls and unpacks hash references.
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil::Hash;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil::List',
    constants => ':elements',
    alias     => {
        pairs       => \&values,
        hash_values => \&values,
        list_values => \&values,
    };

our $TEXT_FORMAT = '%s: %s';
our $TEXT_JOINT  = ', ';


sub text {
    $_[SELF]->debug('%hash text(): ', $_[SELF]->source) if DEBUG;
    my $hash = $_[SELF]->value($_[CONTEXT]);
    join(
        $TEXT_JOINT,
        map { sprintf($TEXT_FORMAT, $_, $hash->{ $_ }) }
        sort keys %$hash
    );
}


sub value {
    $_[SELF]->debug('%hash value(): ', $_[SELF]->source) if DEBUG;
    return { 
        $_[SELF]->[EXPR]->hash_values($_[CONTEXT])
    };
}


sub values {
    $_[SELF]->debug('%hash values(): ', $_[SELF]->source) if DEBUG;
    $_[SELF]->debug("calling on $_[SELF]->[EXPR]") if DEBUG;
    $_[SELF]->[EXPR]->pairs($_[CONTEXT]);
}



1;

__END__

=head1 NAME

Template:TT3::Element::Sigil::Hash - element representing the C<%> sigil

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Sigil>
for representing the hash context sigil C<%>.

It is used to extract the key/value pairs of a hash array.

    [% foo = { a=10, b=20 }
       bar = { c=30, d=40 }
       baz = { %foo, %bar }     # baz contains a=10, b=20, c=30, d=40
    %]

It is also used in function signatures to indicate a hash variable that
should collect all additional named parameters.

    [% foo(%hash) = "You called foo() with $hash.keys.sort.join" %]
    [% foo(a=10, b=20) %]    # You called foo() with a b

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Sigil>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 text()

=head2 value()

=head2 values()

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
