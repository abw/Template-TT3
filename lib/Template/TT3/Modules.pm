package Template::TT3::Modules;

use Template::TT3::Class 
    version  => 3.00,
    base     => 'Badger::Constants',
    constant => {
        # Badger modules we use directly
        FILESYSTEM_MODULE => 'Badger::Filesystem',

        # TT3 modules
        CACHE_MODULE      => 'Template::TT3::Cache',
        DIALECT_MODULE    => 'Template::TT3::Dialect',
        DIALECTS_MODULE   => 'Template::TT3::Dialects',
        ELEMENT_MODULE    => 'Template::TT3::Element',
        ENGINES_MODULE    => 'Template::TT3::Engines',
        EXCEPTIONS_MODULE => 'Template::TT3::Exceptions',
        HUB_MODULE        => 'Template::TT3::Hub',
        PLUGINS_MODULE    => 'Template::TT3::Plugins',
        PROVIDERS_MODULE  => 'Template::TT3::Providers',
        SCANNER_MODULE    => 'Template::TT3::Scanner',
        STORE_MODULE      => 'Template::TT3::Store',
        TAG_MODULE        => 'Template::TT3::Tag',
        TAGSET_MODULE     => 'Template::TT3::Tagset',
        TEMPLATE_MODULE   => 'Template::TT3::Template',
        TEMPLATES_MODULE  => 'Template::TT3::Templates',
        VIEWS_MODULE      => 'Template::TT3::Views',
        IO_HANDLE         => 'IO::Handle',
    },
    exports => {
        any  => 'HUB_MODULE EXCEPTIONS_MODULE TEMPLATE_MODULE
                 DIALECT_MODULE SCANNER_MODULE DIALECT_CLASS
                 TAG_MODULE TAGSET_MODULE ENGINES_MODULE VIEWS_MODULE 
                 ELEMENT_MODULE IO_HANDLE',
        tags => {
            hub => 'FILESYSTEM_MODULE DIALECTS_MODULE TEMPLATES_MODULE 
                    CACHE_MODULE STORE_MODULE PROVIDERS_MODULE PLUGINS_MODULE
                    VIEWS_MODULE',
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

=head1 TODO

This documentation is incompl

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
