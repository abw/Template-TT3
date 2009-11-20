package Template::TT3::Element::Args;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Parens',
    constant  => {
        SEXPR_FORMAT  => "<args:%s>",
    };


1;

__END__

=head1 NAME

Template:TT3::Element::Construct::Args

=head1 DESCRIPTION

This module implements a wafer thin subclass of
L<Template::TT3::Element::Construct::Parens> for representing a parenthesised
list of arguments passed to a function or method C<( ... )>.

    [% foo.bar(a, b, c) %]

=head1 METHODS

This module inherits all the methods from the
L<Template::TT3::Element::Construct>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

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
