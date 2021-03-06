package Template::TT3::Dialects;

use Template::TT3::Class::Factory
    version     => 2.71,
    debug       => 0,
    constants   => 'HASH',
    item        => 'dialect',
    path        => 'Template(X)::(TT3::|)Dialect';


sub init {
    my ($self, $config) = @_;
    $self->init_factory($config);
    $self->{ config } = $config->{ dialects } || $config;
    return $self;
}


sub found {
    my ($self, $type, $item, $args) = @_;
    
    $self->debug("Found result: $type => $item") if DEBUG;

    $self->debug("Returning cached dialect: $self->{ cache }->{ $type }") 
        if DEBUG && $self->{ cache }->{ $type };

    return $self->{ cache }->{ $type } ||= do {
        my $config = $self->{ config };
        my $params = $config->{ $type } || $config;
        my ($dialect, $module);
        
        # If we've got a hash ref as an item then we need to look for a 
        # 'dialect' item in it.  If that's not defined then we try to load
        # the module named by the type name (e.g. tt3 => { ... } loads the
        # TT3 dialect).  Otherwise we load the default dialect.
        if (ref $item eq HASH) {
            $self->debug(
                "found hash config for $item dialect: ", 
                $self->dump_data($item)
            ) if DEBUG;
            
            $dialect = $item->{ dialect } || $type;
            $module  = $self->find($dialect)
                || return $self->error_msg( invalid => dialect => $dialect );
                
            $self->debug("fell back on $dialect mapping to $module") if DEBUG;
            
            # TODO: config merging?
        }
        else {
            $module = $item;
        }

        $self->debug(
            "instantiating dialect $type as $module using config: ", 
            $self->dump_data($params)
        ) if DEBUG;
        
        # add default name for dialect
        $params->{ name } ||= $type;

        $module->new($params);
    };
}


1;

__END__

=head1 NAME

Template::TT3::Dialects - factory module for loading template dialects

=head1 SYNOPSIS

    use Template::TT3::Dialects;
    
    # class methods
    $dialect = Template::TT3::Dialects->dialect;           # default dialect (TT3)
    $dialect = Template::TT3::Dialects->dialect('TT2');    # specific dialect
    
    # object methods
    $dialects = Template::TT3::Dialects->new;
    $dialect  = $dialects->dialect;
    $dialect  = $dialects->dialect('TT2');
    
    # object with configuration options
    $dialects = Template::TT3::Dialects->new( 
        path => ['My::Dialect', 'Your::Dialect'],
    );
    $dialect  = $dialects->dialect;
    $dialect  = $dialects->dialect('TT2');

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating template dialect modules.

It searches for dialect modules in the following places:

    Template::TT3::Dialect
    Template::Dialect
    TemplateX::TT3::Dialect
    TemplateX::Dialect

For example, requesting a C<TT2> dialect returns a
L<Template::TT3::Dialect::TT2> object.

    my $dialect = Template::TT3::Dialects->dialect('TT2');

The default dialect type is C<TT3>, returned as a
L<Template::TT3::Dialect::TT3> object.

    my $dialect = Template::TT3::Dialects->dialect;
    my $dialect = Template::TT3::Dialects->dialect('default');     # same thing

=head1 CONFIGURATION OPTIONS

The following configuration options are defined in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

They should be specified as a list or reference to a hash array of named 
parameters when the factory object is created.

    # either a list of named parameters...
    
    my $dialects = Template::TT3::Dialects->new(
        dialect_path => [
            'My::Dialect', 'Template::TT3::Dialect'
        ],
    );

    # ...or a reference to a hash array
    
    my $dialects = Template::TT3::Dialects->new({
        dialect_path => [
            'My::Dialect', 'Template::TT3::Dialect'
        ],
    });

=head2 dialects

A reference to a hash array explicitly mapping internal dialect names to
external Perl modules. This can be used to override and/or augment the dialect
modules that the factory would normally be able to locate automatically.

    my $dialects = Template::TT3::Dialects->new(
        dialects => {
            foo => 'Some::Other::Dialect::Foo',
            bar => 'Yet::Another::Dialect::Bar'
        },
    );

=head2 dialect_path / path

A reference to a list of module namespaces that the factory should search
to locate dialect modules.  The default path is defined by the L<$PATH>
package variable.

    my $dialects = Template::TT3::Dialects->new(
        dialect_path => [
            'My::Dialect', 'Template::TT3::Dialect'
        ],
    );

=head2 dialect_names / names

A reference to a hash array providing aliases for dialect names.

    my $dialects = Template::TT3::Dialects->new(
        dialect_names => {
            FOO => 'foo',
            bar => 'foo',
        },
    );


=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

=head2 init($config)

A custom initialisation method for the dialects factory.

=head2 found($type, $item, $args)

This method replaces the default L<found()|Badger::Factory/found()> method
inherited from L<Badger::Factory>. It is called by the factory base class when
a module is found and loaded. It implements some additional functionality
specific to the instantiation of dialect objects.

=head1 dialect($type)

Locates, loads and instantiates a dialect module.  This is created as an 
alias to the L<item()|Badger::Factory/item()> method in L<Badger::Factory>.

=head1 dialects()

Method for inspecting or modifying the dialects that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns, and implicitly
the name of the method by which dialects can be created. In this case it is
defined as C<dialect>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Dialect
    Template::Dialect
    TemplateX::TT3::Dialect
    TemplateX::Dialect

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
L<Template::TT3::Dialect>. See L<Template::TT3::Dialect::TT3> for an example.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:



