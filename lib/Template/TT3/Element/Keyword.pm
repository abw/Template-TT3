package Template::TT3::Element::Keyword;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Literal',
    view       => 'keyword',
    constants  => ':elements';


sub parse_word {
    # keywords downgrade themselves to simple words when used after a dot
    shift->become('word')->parse_word(@_);
}


sub parse_dotop {
    # keywords downgrade themselves to simple words when used after a dot
    shift->become('word')->parse_dotop(@_);
}


sub OLD_generate {
    $_[CONTEXT]->generate_keyword(
        $_[SELF]->[TOKEN],
    );
}


1;

__END__

=head1 NAME

Template:TT3::Element::Keyword - base class for keyword elements

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It acts as a
base class for all keyword elements.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_word()

=head2 parse_dotop()

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
L<Template::TT3::Element::Literal>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
