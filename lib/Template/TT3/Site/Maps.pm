package Template::TT3::Site::Maps;

use Template::TT3::Class::Factory
    version   => 2.71,
    debug     => 0,
    item      => 'map',
    path      => 'Template(X)::(TT3::|)Site::Map',
    constants => 'HASH',
    alias     => {
        sitemap => 'map',
    };


sub type_args {
    my $self = shift;
    my $type = shift;
    my $args = @_ == 1 ? shift : { @_ };
    
    $args = {
        default => $args
    } unless ref $args eq HASH;
    
    return ($type, $args);
}


1;

__END__

=head1 NAME

Template::TT3::Maps - factory module for loading template maps

=head1 SYNOPSIS

    use Template::TT3::Maps;
    
    # create a filesystem-based site map object
    my $map = Template::TT3::Site::Maps->map( 
        file => '/path/to/config.yaml' 
    );

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating template site map modules.

It searches for map modules in the following places:

    Template::TT3::Site::Map
    Template::Site::Map
    TemplateX::TT3::Site::Map
    TemplateX::Site::Map

For example, requesting a C<file> map returns a
L<Template::TT3::Site::Map::File> object.

    my $map = Template::TT3::Site::Maps->map('file');

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

=head1 map($type)

Locates, loads and instantiates a site map module.  This is created as an 
alias to the L<item()|Badger::Factory/item()> method in L<Badger::Factory>.

=head1 maps()

Method for inspecting or modifying the site maps that the factory module
manages. This is created as an alias to the L<items()|Badger::Factory/items()>
method in L<Badger::Factory>.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns, and implicitly 
the name of the method by which .  In this case it is defined as C<map>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Site::Map
    Template::Site::Map
    TemplateX::TT3::Site::Map
    TemplateX::Site::Map

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory>, and L<Badger::Base> base classes.

It loads modules and instantiates object that are subclasses of
L<Template::TT3::Site::Map>. See L<Template::TT3::Site::Map::File> for 
an example.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:




