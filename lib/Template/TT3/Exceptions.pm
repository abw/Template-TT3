package Template::TT3::Exceptions;

use Template::TT3::Class::Factory
    version => 2.69,
    debug   => 0,
    item    => 'exception_type',
    path    => 'Template(X)::(TT3::|)Exception';


1;

__END__

=head1 NAME

Template::TT3::Exceptions - factory module for loading and creating exceptions

=head1 SYNOPSIS

    use Template::TT3::Exceptions;
    
    my $factory = Template::TT3::Exceptions->new;
    my $error   = $factory->item( syntax => @args );

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating exception modules used to represent errors.

It searches for exception modules in the following places:

    Template::TT3::Exception
    Template::Exception
    TemplateX::TT3::Exception
    TemplateX::Exception

For example, requesting a C<syntax> exception returns a
L<Template::TT3::Exception::Syntax> object.  Any other arguments
specified are forwarded to the exception constructor method.

    my $error = Template::TT3::Exceptions->item( syntax => @args );

=head1 CONFIGURATION OPTIONS

The following configuration options are defined in addition to those inherited
from the L<Template::TT3::Factory>, L<Template::TT3::Base>, L<Badger::Factory>
and L<Badger::Base> base classes.

They should be specified as a list or reference to a hash array of named 
parameters when the factory object is created.

    # either a list of named parameters...
    
    my $exceptions = Template::TT3::Exceptions->new(
        exception_type_path => [
            'My::Exception', 'Template::TT3::Exception'
        ],
    );

    # ...or a reference to a hash array
    
    my $exceptions = Template::TT3::Exceptions->new({
        exception_type_path => [
            'My::Exception', 'Template::TT3::Exception'
        ],
    });

=head2 exception_types

A reference to a hash array explicitly mapping internal exception type names
to external Perl modules. This can be used to override and/or augment the
exception type modules that the factory would normally be able to locate
automatically.

    my $exceptions = Template::TT3::Exceptions->new(
        exception_types => {
            foo => 'Some::Other::Exception::Foo',
            bar => 'Yet::Another::Exception::Bar'
        },
    );

=head2 exception_type_path / path

A reference to a list of module namespaces that the factory should search
to locate exception_type modules.  The default path is defined by the L<$PATH>
package variable.

    my $exceptions = Template::TT3::Exceptions->new(
        exception_type_path => [
            'My::Exception', 'Template::TT3::Exception'
        ],
    );

=head2 exception_type_names / names

A reference to a hash array providing aliases for exception_type names.

    my $exceptions = Template::TT3::Exceptions->new(
        exception_type_names => {
            FOO => 'foo',
            bar => 'foo',
        },
    );

=head1 METHODS

This module inherits all methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.
The following methods are automatically provided by the L<Badger::Factory>
base class.

=head2 exception_type($type,@args) / item($type,@args)

Locates, loads and instantiates an exception module. This is created as an
alias to the L<item()|Badger::Factory/item()> method in L<Badger::Factory>.
Note that we have to use this clumsy name to avoid clashing with the
L<exception()|Badger::Base/exception()> method inherited from L<Badger::Base>.

=head2 exception_types()

Method for inspecting or modifying the exceptions that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns, and implicitly
the name of the method by which exception objects can be created. In this case
it is defined as C<exception_type>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Exception
    Template::Exception
    TemplateX::TT3::Exception
    TemplateX::Exception

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
L<Template::TT3::Exception>.  See L<Template::TT3::Exception::Syntax> and 
L<Template::TT3::Exception::Undef> for examples.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
