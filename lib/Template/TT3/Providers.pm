package Template::TT3::Providers;

use Template::TT3::Class::Factory
    version => 2.69,
    debug   => 0,
    item    => 'provider',
    path    => 'Template(X)::(TT3::|)Provider',
    default => 'cwd';


1;

__END__

=head1 NAME

Template::TT3::Providers - factory module for loading template providers

=head1 SYNOPSIS

    use Template::TT3::Providers;
    
    # class methods
    $provider = Template::TT3::Providers->provider;          # default provider (cwd)
    $provider = Template::TT3::Providers->provider('file');  # specific provider
    
    # object methods
    $providers = Template::TT3::Providers->new;
    $provider  = $providers->provider;
    $provider  = $providers->provider('file');
    
    # object with configuration options
    $providers = Template::TT3::Providers->new( 
        path => ['My::Provider', 'Your::Provider'],
    );
    $provider  = $providers->provider;
    $provider  = $providers->provider('file');

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating template provider modules. Provider modules are responsible
for loading templates from a filesystem, database, remote service, or by some
other mechanism.

It searches for provider modules in the following places:

    Template::TT3::Provider
    Template::Provider
    TemplateX::TT3::Provider
    TemplateX::Provider

For example, requesting a C<file> provider returns a
L<Template::TT3::Provider::File> object.

    my $provider = Template::TT3::Providers->provider('file');

The default provider type is C<Cwd>, returned as a
L<Template::TT3::Provider::Cwd> object.  This loads templates from the
local filesystem, using the current working directory as the default 
location.

    my $provider = $providers->provider;
    my $provider = $providers->provider('cwd');         # same thing
    my $provider = $providers->provider('default');     # same thing

=head1 CONFIGURATION OPTIONS

The following configuration options are defined in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

They should be specified as a list or reference to a hash array of named 
parameters when the factory object is created.

    # either a list of named parameters...
    
    my $providers = Template::TT3::Providers->new(
        provider_path => [
            'My::Provider', 'Template::TT3::Provider'
        ],
    );

    # ...or a reference to a hash array
    
    my $providers = Template::TT3::Providers->new({
        provider_path => [
            'My::Provider', 'Template::TT3::Provider'
        ],
    });

=head2 providers

A reference to a hash array explicitly mapping internal provider names to
external Perl modules. This can be used to override and/or augment the provider
modules that the factory would normally be able to locate automatically.

    my $providers = Template::TT3::Providers->new(
        providers => {
            foo => 'Some::Other::Provider::Foo',
            bar => 'Yet::Another::Provider::Bar'
        },
    );

=head2 provider_path / path

A reference to a list of module namespaces that the factory should search
to locate provider modules.  The default path is defined by the L<$PATH>
package variable.

    my $providers = Template::TT3::Providers->new(
        provider_path => [
            'My::Provider', 'Template::TT3::Provider'
        ],
    );

=head2 provider_names / names

A reference to a hash array providing aliases for provider names.

    my $providers = Template::TT3::Providers->new(
        provider_names => {
            FOO => 'foo',
            bar => 'foo',
        },
    );

=head1 METHODS

This module inherits all methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.
The following methods are automatically provided by the L<Badger::Factory>
base class.

=head2 provider($type)

Locates, loads and instantiates a provider module.  This is created as an 
alias to the L<item()|Badger::Factory/item()> method in L<Badger::Factory>.

=head2 providers()

Method for inspecting or modifying the providers that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns, and implicitly
the name of the method by which providers objects can be created. In this case
it is defined as C<provider>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Provider
    Template::Provider
    TemplateX::TT3::Provider
    TemplateX::Provider

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory>, and L<Badger::Base> base classes.

It is constructed using the L<Template::TT3::Class::Factory> class 
metaprogramming module.

It loads modules and instantiates object that are subclasses of
L<Template::TT3::Provider>. See L<Template::TT3::Provider::File> and 
L<Template::TT3::Provider::Cwd> for examples of specific provider modules.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:




