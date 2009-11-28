package Template::TT3::Modules;

use Template::TT3::Class 
    version  => 3.00,
    base     => 'Badger::Constants',
    constant => {
        FILESYSTEM_MODULE => 'Badger::Filesystem',
        HUB_MODULE        => 'Template::TT3::Hub',
        CACHE_MODULE      => 'Template::TT3::Cache',
        STORE_MODULE      => 'Template::TT3::Store',
        DIALECTS_MODULE   => 'Template::TT3::Dialects',
        TEMPLATE_MODULE   => 'Template::TT3::Template',
        TEMPLATES_MODULE  => 'Template::TT3::Templates',
        PROVIDERS_MODULE  => 'Template::TT3::Providers',
        PLUGINS_MODULE    => 'Template::TT3::Plugins',
        EXCEPTIONS_MODULE => 'Template::TT3::Exceptions',
    },
    exports => {
        any  => 'HUB_MODULE EXCEPTIONS_MODULE TEMPLATE_MODULE',
        tags => {
            hub => 'FILESYSTEM_MODULE DIALECTS_MODULE TEMPLATES_MODULE 
                    CACHE_MODULE STORE_MODULE PROVIDERS_MODULE PLUGINS_MODULE',
        },
    };

1;

__END__

=head1 NAME

Template::TT3::Modules - defines constants for TT3 module names

=head1 SYNOPSIS

    use Template::TT3::Modules 'HUB_MODULE';
    
    print HUB_MODULE;           # Template::TT3::Hub

=head1 DESCRIPTION

This module defines a number of constants as aliases to the names of 
various TT3 modules.

=head1 CONSTANTS

=head2 HUB_MODULE

Defined as C<Template::TT3::Hub>.

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Badger::Exporter> for more information on exporting variables.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
