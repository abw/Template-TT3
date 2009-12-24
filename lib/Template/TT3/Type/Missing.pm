package Template::TT3::Type::Missing;

use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Type::Undef';


1;

__END__

=head1 NAME

Template::TT3::Type::Missing - specialist type for missing values

=head1 DESCRIPTION

C<Template::TT3::Type::Missing> is a specialised subclass of
L<Template::TT3::Type::Undef> used in conjunction with 
L<Template::TT3::Variable::Missing> for representing undefined values.

TODO: Undefined value are those where a variable exists and is explicitly 
set to C<undef>, e.g. 'foo' in { foo =E<gt> undef }.  Missing values are those
where the variable doesn't exists, e.g. 'foo' in { bar =E<gt> 10 }

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
L<Template::TT3::Type::Undef>,
L<Template::TT3::Variable::Undef>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4
