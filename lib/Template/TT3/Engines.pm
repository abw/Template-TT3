package Template::TT3::Engines;

use Template::TT3::Class::Factory
    version   => 2.69,
    debug     => 0,
    item      => 'engine',
    path      => 'Template(X)::(TT3::|)Engine';

1;


__END__

=head1 NAME

Template::TT3::Engines - factory module for loading template engines

=head1 SYNOPSIS

    use Template::TT3::Engines;
    
    # class methods
    $engine = Template::TT3::Engines->engine;           # default engine (TT3)
    $engine = Template::TT3::Engines->engine('TT2');    # specific engine
    
    # object methods
    $engines = Template::TT3::Engines->new;
    $engine  = $engines->engine;
    $engine  = $engines->engine('TT2');
    
    # object with configuration options
    $engines = Template::TT3::Engines->new( 
        path => ['My::Engine', 'Your::Engine'],
    );
    $engine  = $engines->engine;
    $engine  = $engines->engine('TT2');

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating template engine modules.

It searches for engine modules in the following places:

    Template::TT3::Engine
    Template::Engine
    TemplateX::TT3::Engine
    TemplateX::Engine

For example, requesting a C<TT2> engine returns a
L<Template::TT3::Engine::TT2> object.

    my $engine = Template::TT3::Engines->engine('TT2');

The default engine type is C<TT3>, returned as a L<Template::TT3::Engine::TT3>
object.

    my $engine = Template::TT3::Engines->engine;
    my $engine = Template::TT3::Engines->engine('default');     # same thing

=head1 CONFIGURATION OPTIONS

The following configuration options are defined in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

They should be specified as a list or reference to a hash array of named 
parameters when the factory object is created.

    # either a list of named parameters...
    
    my $engines = Template::TT3::Engines->new(
        engine_path => [
            'My::Engine', 'Template::TT3::Engine'
        ],
    );

    # ...or a reference to a hash array
    
    my $engines = Template::TT3::Engines->new({
        engine_path => [
            'My::Engine', 'Template::TT3::Engine'
        ],
    });

=head2 engines

A reference to a hash array explicitly mapping internal engine names to
external Perl modules. This can be used to override and/or augment the engine
modules that the factory would normally be able to locate automatically.

    my $engines = Template::TT3::Engines->new(
        engines => {
            foo => 'Some::Other::Engine::Foo',
            bar => 'Yet::Another::Engine::Bar'
        },
    );

=head2 engine_path / path

A reference to a list of module namespaces that the factory should search
to locate engine modules.  The default path is defined by the L<$PATH>
package variable.

    my $engines = Template::TT3::Engines->new(
        engine_path => [
            'My::Engine', 'Template::TT3::Engine'
        ],
    );

=head2 engine_names / names

A reference to a hash array providing aliases for engine names.

    my $engines = Template::TT3::Engines->new(
        engine_names => {
            FOO => 'foo',
            bar => 'foo',
        },
    );

=head1 METHODS

This module inherits all methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.
The following methods are automatically provided by the L<Badger::Factory>
base class.

=head2 engine($type)

Locates, loads and instantiates an engine module.  This is created as an 
alias to the L<item()|Badger::Factory/item()> method in L<Badger::Factory>.

=head2 engines()

Method for inspecting or modifying the engines that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns, and implicitly
the name of the method by which engine objects can be created. In this case it
is defined as C<engine>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Engine
    Template::Engine
    TemplateX::TT3::Engine
    TemplateX::Engine

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
L<Template::TT3::Engine>.  See L<Template::TT3::Engine::TT2> and 
L<Template::TT3::Engine::TT3> for examples.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
