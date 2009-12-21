package Template::TT3::Types;

use Template::TT3::Class::Factory
    version     => 2.69,
    debug       => 0,
    item        => 'type',
    path        => 'Template(X)::(TT3::|)Type',
    utils       => 'params',
    constants   => 'ARRAY DELIMITER',
    names       => {
        # match Perl's UPPER CASE ref() types
        SCALAR => 'text',
        ARRAY  => 'list',
        HASH   => 'hash',
        CODE   => 'code',
        GLOB   => 'glob',       # TODO

# Don't think we need these any more as the mapping is done in T~Variables
#       LIST   => 'list',
#       TEXT   => 'text',
#       UNDEF  => 'undef',
    };


our $VTABLES = { };


sub vtable {
    my ($self, $type) = @_;
    return $VTABLES->{ $type } 
       ||= $self->type($type)->methods;
}


sub vtables {
    my $self  = shift->prototype;
    my $types = @_ == 1 ? shift : [ @_ ];
    
    $types = [ split(DELIMITER, $types) ] 
        unless ref $types;

    return $self->error_msg( invalid => types => $types )
        unless ref $types eq ARRAY;
    
    $self->debug(
        "vtables() types: ", 
        $self->dump_data($types)
    ) if DEBUG;
    
    return {
        map { $_ => $VTABLES->{ $_ } || $self->type($_)->methods }
        @$types
    };
}


sub found {
    my ($self, $type, $module) = @_;
    return $module;
}


sub create {
    my $self = shift;
    my $name = shift;
    my $type = $self->type($name)
        || return $self->error_msg( invalid => type => $name );
    return $type->new(@_);
}

        
1;

__END__

=head1 NAME

Template::TT3::Types - factory module for loading data types

=head1 SYNOPSIS

    use Template::TT3::Types;
    
    my $text = Template::TT3::Types->create( 
        text => 'Hello World' 
    );
    print "text is ", $text->length(), " characters long\n";    
    
    my $list = Template::TT3::Types->create( 
        list => [ 'Hello', 'World' ] 
    );
    print "list has ", $list->size(), " items\n";    
    
    my $hash = Template::TT3::Types->create( 
        hash => { Hello => 'World' } 
    );
    print "hash has ", $hash->size(), " pairs\n";    

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating data type modules.

It searches for type modules in the following places:

    Template::TT3::Type
    Template::Type
    TemplateX::TT3::Type
    TemplateX::Type

For example, creating a C<list> type returns a
L<Template::TT3::Type::List> object.

    my $list = Template::TT3::Types->create( list => \@data );

=head1 CONFIGURATION OPTIONS

The following configuration options are defined in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

They should be specified as a list or reference to a hash array of named 
parameters when the factory object is created.

    # either a list of named parameters...
    
    my $types = Template::TT3::Types->new(
        type_path => [
            'My::Type', 'Template::TT3::Type'
        ],
    );

    # ...or a reference to a hash array
    
    my $types = Template::TT3::Types->new({
        type_path => [
            'My::Type', 'Template::TT3::Type'
        ],
    });

=head2 types

A reference to a hash array explicitly mapping internal type names to
external Perl modules. This can be used to override and/or augment the type
modules that the factory would normally be able to locate automatically.

    my $types = Template::TT3::Types->new(
        types => {
            foo => 'Some::Other::Type::Foo',
            bar => 'Yet::Another::Type::Bar'
        },
    );

=head2 type_path / path

A reference to a list of module namespaces that the factory should search
to locate type modules.  The default path is defined by the L<$PATH>
package variable.

    my $types = Template::TT3::Types->new(
        type_path => [
            'My::Type', 'Template::TT3::Type'
        ],
    );

=head2 type_names / names

A reference to a hash array providing aliases for type names.

    my $types = Template::TT3::Types->new(
        type_names => {
            FOO => 'foo',
            bar => 'foo',
        },
    );

=head1 METHODS

The following methods are implemented or automatically added by the 
L<Template::TT3::Class::Factory> metaprogramming module in addition to 
those inherited from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.

=head2 type($type)

Locates and loads a data type module and returns the class name. This is
created as an alias to the L<item()|Badger::Factory/item()> method in
L<Badger::Factory>. 

Note that the method doesn't automatically create a new data type object as
most factory modules do. TT uses this module to load virtual method tables for
types (via the L<vtable()> and L<vtables()> methods) but not for creating
instances of the data type objects. See L<create()> for a method that does.

=head2 types()

Method for inspecting or modifying the data types that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head2 create($type,@data)

Constructor method which creates a new instance variable of a particular 
type.

    my $text = $types->create( text => 'Hello World' );
    my $list = $types->create( list => [10, 20] );
    my $hash = $types->create( hash => { x=>10, y=>20 } );

=head2 vtable($type)

Returns a reference to a hash array mapping virtual method names to their
implementations for the data type specified as an argument.

=head2 vtables($types)

Returns a reference to a hash array containing virtual method tables (see
L<vtable()>) for the types specified as argument(s).  Types can be specified
as a list of names:

    my $vtables = $types->vtables('text', 'list', 'hash');

Or as a reference to a list of names;

    my $vtables = $types->vtables(['text', 'list', 'hash']);

Or as a single text string containing whitespace-delimited names:

    my $vtables = $types->vtables('text list hash');

=head1 INTERNAL METHODS

=head2 found($type,$module)

This replaces the default method inherited from the L<Badger::Factory> base
class. Instead of automatically creating an object when the L<type()> method
is called, it instead returns the class name of the module implementing it.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns. In this case it
is defined as C<type>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Type
    Template::Type
    TemplateX::TT3::Type
    TemplateX::Type

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
L<Template::TT3::Type>.  See L<Template::TT3::Type::Text>, 
L<Template::TT3::Type::List> and L<Template::TT3::Type::Hash> for examples.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
