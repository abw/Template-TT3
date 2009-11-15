package Template::TT3::Views;

use Badger::Factory::Class
    version => 3.00,
    debug   => 0,
    item    => 'view',
    base    => 'Template::TT3::Base',
    path    => 'Template::TT3::View 
                Template::View 
                TemplateX::TT3::View
                TemplateX::View';


# This method overrides the default Badger::Factory behaviour of throwing
# an error when a requested module is not found.  B::F needs some refactoring
# so this may change.

# See T::TT3::Tokens for an example of an object that calls this 
# speculatively.  We don't want to throw an error if the item can't 
# be found so we decline with an undef instead.

sub not_found {
    return undef;
}

1;

__END__

=head1 NAME

Template::TT3::Views - factory module for template view objects

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 view($name, \%config)

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
