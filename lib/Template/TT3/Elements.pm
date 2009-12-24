package Template::TT3::Elements;

use Template::TT3::Class::Factory
    version   => 2.69,
    debug     => 0,
    item      => 'element',
    utils     => 'params',
    path      => 'Template(X)::(XS::)TT3::Element',
    constants => 'PKG';


# We're lazy, so we rely on Badger::Factory (the base class of T::Elements
# which in turn is the base class of T::Grammar) to convert a simple string 
# like "foo_bar" into the appropriate T::Element::FooBar module name.  We
# use dots to delimit namespaces, e.g. 'numeric.add' is expanded to 
# T::Element::Numeric::Add.  However, because we're *really* lazy and can't
# be bothered quoting lots of strings like 'numeric.add' (they have to be
# quoted because the dot can't be bareworded on the left of =>) we define
# a bunch of prefixes that get pre-expanded when the symbol table is imported.
# e.g 'num_add' becomes 'numeric.add' becomes 'T::Element::Numeric::Add'

our $PREFIXES = {
    # short names
    op_         => 'operator.',
    txt_        => 'operator.text.',
    num_        => 'operator.number.',
    bool_       => 'operator.boolean.',
    cmd_        => 'command.',
    ctr_        => 'control.',
    con_        => 'construct.',
    sig_        => 'sigil.',
    var_        => 'variable.',
    html_       => 'HTML.',
    pod_        => 'pod.',

    # long names
    operator_   => 'operator.',
    text_       => 'operator.text.',
    number_     => 'operator.number.',
    boolean_    => 'operator.boolean.',
    command_    => 'command.',
    control_    => 'control.',
    construct_  => 'construct.',
    sigil_      => 'sigil.',
    variable_   => 'variable.',
};


*init = \&init_elements;


sub init_elements {
    my ($self, $config) = @_;
    $self->init_factory($config);
    $self->{ prefixes } = $self->class->hash_vars( 
        PREFIXES => $config->{ prefixes }
    );
    $self->debug("prefixes: ", $self->dump_data($self->{ prefixes })) if DEBUG;
    return $self;
}


sub type_args {
    my $self = shift;
    my $type = shift;
    
    # expand any prefix_
    $type =~ s/^([^\W_]+_)/$self->{ prefixes }->{ $1 } || $1/e;
    
    return ($type, @_);
}


sub create {
    my $self = shift->prototype;
    my $type = shift;
    $self->constructor($type)->(@_);
}


sub constructor {
    my $self   = shift->prototype;
    my $type   = shift;
    my $params = params(@_);

    # add backref to this factory for element instances to use
    # TODO: figure out how to clean up the circular references
    $params->{ elements } = $self;

    return $self->{ constructors }->{ $type } 
       ||= $self->element($type)
                ->constructor($params);
}


sub found {
    my ($self, $type, $module) = @_;
    return $module;
}


sub not_found {
    shift->error_msg( invalid => element => @_ );
}
            

sub module_names {
    my $self = shift;
    my @bits = 
        map {
            join( '',
                map { s/(.)/\U$1/; $_ }
                split('_')
            );
        }
        map { split /[\.]+/ } @_;

    return (
        join( PKG, map { ucfirst $_ } @bits ),
        join( PKG, @bits )
    );
}



__END__

=head1 NAME

Template::TT3::Elements - factory module for loading element modules

=head1 SYNOPSIS

    use Template::TT3::Elements;
    
    my $elems = Template::TT3::Element->new(
        # custom elements
        elements => {
            foo => 'Some::Element::Module::Foo',
        },
        # custom element path
        element_path => [
            'My::Element', 'Template::TT3::Element',
        ],
    };
    
    my $text = $elems->create( text => 'Hello World' );
    my $num  = $elems->create( number => 42 );

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating element modules.  These are used to represent the component
parts (a.k.a. tokens, expressions, opcodes, nodes, etc) of compiled templates.

It searches for element modules in the following places:

    Template::TT3::Element
    Template::Element
    TemplateX::TT3::Element
    TemplateX::Element

For example, creating a C<text> element returns a
L<Template::TT3::Element::Text> object.

    my $text = Template::TT3::Elements->create( 
        text => 'Hello World' 
    );

=head1 CONFIGURATION OPTIONS

The following configuration options are defined in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

They should be specified as a list or reference to a hash array of named 
parameters when the factory object is created.

    # either a list of named parameters...
    
    my $elements = Template::TT3::Elements->new(
        element_path => [
            'My::Element', 'Template::TT3::Element'
        ],
    );

    # ...or a reference to a hash array
    
    my $elements = Template::TT3::Elements->new({
        element_path => [
            'My::Element', 'Template::TT3::Element'
        ],
    });

=head2 elements

A reference to a hash array explicitly mapping internal element names to
external Perl modules. This can be used to override and/or augment the element
modules that the factory would normally be able to locate automatically.

    my $elements = Template::TT3::Elements->new(
        elements => {
            foo => 'Some::Other::Element::Foo',
            bar => 'Yet::Another::Element::Bar'
        },
    );

=head2 element_path / path

A reference to a list of module namespaces that the factory should search
to locate element modules.  The default path is defined by the L<$PATH>
package variable.

    my $elements = Template::TT3::Elements->new(
        element_path => [
            'My::Element', 'Template::TT3::Element'
        ],
    );

=head2 element_names / names

A reference to a hash array providing aliases for element names.

    my $elements = Template::TT3::Elements->new(
        element_names => {
            FOO => 'foo',
            bar => 'foo',
        },
    );

=head2 prefixes

A reference to a hash array a prefixes that should be expanded in element
types.  The default set of prefixes is defined in the L<$PREFIXES> package
variable.  It includes prefixes like C<op_> as an alias for C<operator.>,
and C<num_> as an alias for C<operator.number.>.

    my $elements = Template::TT3::Elements->new(
        prefixes => {
            html_ => 'markup.HTML.',
        }
    );

With the C<html_> prefix defined we can then write:

    my $table = $elements->create(
        html_table => '...',
    );

This is shorthand for:

    my $table = $elements->create(
        'markup.HTML.table => '...',
    );

That would be resolved to the C<Template::TT3::Element::Markup::HTML::Table>
module.  Note that this module doesn't actually exist, it's just being used
as an example of the prefix expansion.

=head1 METHODS

The following methods are implemented or automatically added by the 
L<Template::TT3::Class::Factory> metaprogramming module in addition to 
those inherited from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.

=head2 element($type)

Locates and loads an element module and returns the class name. This is
created as an alias to the L<item()|Badger::Factory/item()> method in
L<Badger::Factory>. 

Note that the method doesn't automatically create a new element object as
most factory modules do. TT uses this module to provide constructor functions
(via L<constructor()>) that create instances of the elements rather than 
creating element objects directly.  See L<create()> for a method that does
create element objects.

=head2 element()

Method for inspecting or modifying the element types that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head2 create($type,@data)

Constructor method which creates a new instance variable of a particular 
element.

    my $text = $elems->create( text => 'Hello World' );
    my $list = $elems->create( number => 42 );

=head2 constructor($type,$config)

Returns a reference to a constructor function which can be used to create 
element objects of a particular type, denoted by the first argument, C<$type>.

    my $Text = $elems->constructor('text');
    my $text = $Text->('Hello World');

Optional configuration parameters can be specified after the element type.
These are forwarded to the
L<constructor()|Template::TT3::Element/constructor()> method of the
appropriate element class.

=head1 INTERNAL METHODS

=head2 init_elements($config)

Custom initialisation method which performs some additional configuration
for this factory module.

=head2 type_args($type,@args)

This replaces the default method inherited from the L<Badger::Factory> base
class. It expand any prefix at the start of C<$type> that matches an entry in
the C<$PREFIXES> table, or was specified using the L<prefixes> configuration
option.

=head2 found($type,$module)

This replaces the default method inherited from the L<Badger::Factory> base
class. Instead of automatically creating an element object when the
L<element()> method is called, it instead returns the class name of the module
implementing it.

=head2 not_found($type)

This replaces the default method inherited from the L<Badger::Factory> base
class. It throws an error if an element cannot be found.

=head2 module_names($type)

This replaces the default method inherited from the L<Badger::Factory> base
class. It allows type names to contain periods as package separator.  e.g.
requesting an element with a type of C<foo.bar_baz> will resolve to the 
C<Template::TT3::Element::Foo::BarBaz> module (or would if it existed outside
the realm of this example).

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns. In this case it
is defined as C<element>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Element
    Template::Element
    TemplateX::TT3::Element
    TemplateX::Element

=head2 $PREFIXES

This defines the default set of prefixes that can be used as shorthand for
longer element names.  At the time of writing it contains the prefixes
listed below.  Note however that this is subject to change.  Consult the
source code for the definitive list (and please consider submitting a 
documentation patch if you find it to be in error).

    Prefix      Expanded To
    --------------------------------
    bool_       operator.boolean.
    boolean_    operator.boolean.
    cmd_        command.
    command_    command.
    con_        construct.
    construct_  construct.
    ctr_        control.
    control_    control.
    html_       HTML.
    num_        operator.number.
    number_     operator.number.
    op_         operator.
    operator_   operator.
    sig_        sigil.
    sigil_      sigil.
    txt_        operator.text.
    text_       operator.text.
    var_        variable.
    variable_   variable.

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
L<Template::TT3::Element>.  See L<Template::TT3::Element::Text> and 
L<Template::TT3::Element::Block> for examples.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

1;
