package Template::TT3::Type::Undef;

use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Type';


1;

__END__

=head1 NAME

Template::TT3::Type::Undef - specialist type for the undefined value

=head1 DESCRIPTION

C<Template::TT3::Type::Undef> is a specialised subclass of
L<Template::TT3::Type> used in conjunction with
L<Template::TT3::Variable::Undef> for representing the undefined value,
C<undef>.

It inherits everything from the L<Template::TT3::Type> base class, including
methods like L<defined()|Template::TT3::Type/defined()> and
L<undefined()|Template::TT3::Type/undefined()> which can be used as virtual
methods to test if a value is defined or not.

    [% if foo.defined %]
        ...
    [% end %]

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::TT3::Type>,
L<Template::TT3::Variable::Undef>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4
