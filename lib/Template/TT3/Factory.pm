package Template::TT3::Factory;

use Template::TT3::Class
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Base Badger::Factory',
    constants => DEFAULT,
    alias     => {
        init  => \&init_factory,
    };

our $NAMES = {
    tt2     => 'TT2',
    tt3     => 'TT3',
};

our $DEFAULT = 'TT3';

sub init_factory {
    my ($self, $config) = @_;

    # attach factory to the hub that create it, or the default prototype hub
    $self->init_hub($config);

    $self->debug(
        "looking for names in ", 
        join(', ', $self->class->heritage)
    ) if DEBUG;
    
    # merge all $NAMES definitions into a new 'names'
    $config->{ names } = $self->class->hash_vars( 
        NAMES => $config->{ names } 
    );

    # let the base class factory initialiser have a go
    return $self->SUPER::init_factory($config);
}


1;

__END__

=head1 NAME

Template::TT3::Factory - base class for factory modules 

=head1 SYNOPSIS

    # This module is used internally to create factory modules responsible 
    # for loading other modules.  e.g. Template::TT3::Engines.
    
    package Template::TT3::Engines;
    
    use Template::TT3::Class::Factory
        version   => 3.00,
        debug     => 0,
        item      => 'engine',
        path      => 'Template(X)::(TT3::|)Engine';

=head1 DESCRIPTION

This module is a common base class for all TT3 factory modules that are
responsible for loading other modules. For example, the
L<Template::TT3::Engines> modules is a factory module for loading
C<Template::TT3::Engine::*> modules.  

C<Template::TT3::Factory> is a thin subclass of L<Badger::Factory>.  It
exists to provide a convenient place to define any functionality or 
declarations that are common to all TT3 factory modules.

The L<Template::TT3::Class::Factory> module is defined as a thin wrapper
around L<Badger::Factory::Class> to aid in the construction of factory
modules.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base
classes.

=head2 init($config)

This is an alias to the L<init_factory()> method.  It replaces the default 
L<init()|Badger::Base/init()> method inherited from L<Badger::Factory>.

=head2 init_factory($config)

This is a thin wrapper around the
L<init_factory()|Badger::Factory/init_factory()> method inherited from
L<Badger::Factory>.  It performs some additional configuration to make the
declarations in C<$MAP> accessible to subclasses.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $NAMES

This defines a lookup table for resolving modules with alternate spellings or
unusual capitalisations (where "unusual" is defined as anything that can't 
be resolved automatically).

The L<Badger::Factory> base class module uses the
L<camel_case()|Badger::Utils/camel_case()> function to construct a full module
name from a short identifier passed to it. It appends the resultant name to
each module base specified in its L<path|Badger::Factory/path> and attempts to
load the module. For example, consider a factory with a path defined as 
follows:

    my $widgets = Badger::Factory->new(
        item => 'widget',
        path => ['Foo', 'Bar']
    );

Requesting an item named C<wiz_bang> will instruct the factory to look for 
a C<wiz_bang> module as either C<Foo::WizBang> or C<Bar::WizBang>.

    # load and instantiate either Foo::WizBang or Bar::WizBang
    my $widget = $widgets->widget('wiz_bang');

In the case of modules whose names include capitalised acronyms, specifically
"TT2", "TT3" and "HTML", a request for a lower case equivalent, "tt2", "tt3"
or "html" will generate incorrect capitalisations of "Tt2", "Tt3" and "Html"
respectively.

The C<$NAMES> table define correct capitalisations for these values.  These
definitions are then inherited by all other TT3 factory modules. 

    our $NAMES = {
        tt2     => 'TT2',
        tt3     => 'TT3',
    }

=head2 $DEFAULT

This defines the C<default> value for TT3 factort modules to be C<TT3>.
e.g. the default engine returned by L<Template::TT3::Engines> is the C<TT3>
engine implemented as L<Template::TT3::Engine::TT3>.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Base>,
L<Badger::Factory>, and L<Badger::Base> base classes.

It is itself the base class for L<Template::TT3::Engines>,
L<Template::TT3::Dialects>, L<Template::TT3::Providers>, and various other
factory modules.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


