package Template::TT3::Element::Construct::List;

use Template::TT3::Class 
    debug     => 0,
    base      => 'Template::TT3::Element::Construct',
    view      => 'list',
    constants => ':elements',
    constant  => {
        FINISH        => ']',
        SEXPR_FORMAT  => "<list:%s>",
        SOURCE_FORMAT => '[ %s ]',
    },
    alias     => {
        values => \&value,
    };


sub text {
    $_[SELF]->debug("list text(): ", $_[SELF]->source) if DEBUG;
    return join(
        '',
        $_[SELF]->[EXPR]->text($_[CONTEXT])
    );
}


sub value {
    $_[SELF]->debug("list value(): ", $_[SELF]->source) if DEBUG;
    return [
        $_[SELF]->[EXPR]->values($_[CONTEXT])
    ];
}


1;

__END__

=head1 NAME

Template:TT3::Element::Construct::List

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Construct>
for representing the list construct C<[ ... ]>.

    [% foo = [1, 2, 3] %]

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Construct>, L<Template::TT3::Element>,
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
L<Template::TT3::Element::Construct>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
