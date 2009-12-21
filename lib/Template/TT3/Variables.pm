package Template::TT3::Variables;

use Template::TT3::Class::Factory
    version     => 2.69,
    debug       => 0,
    item        => 'variable',
    path        => 'Template(X)::(TT3::|)Variable',
    utils       => 'params',
    import      => 'CLASS',
    constants   => 'HASH',
    names       => {                    # NOTE: this defines $VARIABLE_NAMES
        # There are the types returned by Perl's ref()
        SCALAR  => 'code',
        ARRAY   => 'list',
        HASH    => 'hash',
        CODE    => 'code',
#       GLOB    => 'glob',

        # These are the internal names we use for everything else
        map { $_ => $_ }
        qw( text list hash code object undef missing )
#       params,         # TODO: decide what we're doing with this
    },
    messages => {
        bad_type => 'Invalid type specification for %s: %s',
    };


sub builtin {
    my $self   = shift->prototype;
    my $types  = $VARIABLE_NAMES;       # Defined by 'names' hook above
    my $loads  = { };

    $self->debug(
        "builtin() types: ", 
        $self->dump_data($types)
    ) if DEBUG;
    
    foreach my $type (keys %$types) {
        $loads->{ $type } = $self->variable($type);
    }
    
    return $loads;
}


sub constructors {
    my $self    = shift->prototype;
    my $builtin = $self->builtin;
    my $userdef = params(@_);
    my $types   = $self->hub->types;

    my $input = { 
        # we're not interested in the class names that are in the $builtin
        # values, we just want a mapping from key to key, e.g. undef => undef
        (   
            map { $_ => $_ }
            keys %$builtin
        ),
        # then we allow the user-defined types to over-ride them and/or add 
        # to them, e.g. undef => blank, My::Class => { ... }, etc.
        %$userdef 
    };
    
    $self->debug(
        "merged variable types:", 
        $self->dump_data($input), "\n",
    ) if DEBUG;
    
    my $output = { };
    
    foreach (keys %$input) {
        my $key = $_;
        my $cfg = $input->{ $key }; 
        my ($type, $vtable, $utable, $methods);

        # TODO: allow methods to be set to 0: text => { methods => 0 }
        # or as a short-cut, text => 0.  I don't think we can allow any 
        # false value to skip the type altogether as that would allow the 
        # user to disable the text, hash, list or other inbuilt types which
        # would probably cause TT to fail.

        if (! $cfg) {
            $type = $builtin->{ $key } && $key      # a builtin type
                 || 'object';                       # or an object type
            $methods = { };
        }
        elsif (ref $cfg eq HASH) {
            $type = $cfg->{ type }                  # declared type
                 || $builtin->{ $key } && $key      # or a builtin type
                 || 'object';                       # or an object type
        }
        elsif (ref $cfg) {
            return $self->error_msg( bad_type => $key, $cfg );
        }
        else {
            $type = $cfg;
            $cfg = { };
        }

        unless ($methods) {
            # merge inbuilt virtual methods with any user-supplied ones
            $vtable = $types->try->vtable($type) || { };
            $utable = $cfg->{ methods } || $cfg;
            $methods = { %$vtable, %$utable };
        }

        $output->{ $key } = $self->variable($type)->constructor( 
            methods => $methods
        );
        
        $self->debug(
            "variable type: $key => $type => ", 
            $self->dump_data($methods)
        ) if DEBUG
    }

    return $output;
}


sub found {
    my ($self, $type, $module) = @_;
    return $module;
}


1;

__END__

=head1 NAME

Template::TT3::Variables - factory module for loading variable modules

=head1 SYNOPSIS

    use Template::TT3::Variables;
    
    my $types = Template::TT3::Variables->constructors(
        undef => 'missing',                 # map data types
        text  => {                          # add virtual methods
            foo => sub { ... },
            bar => sub { ... },
        },
        'Wiz::Bang' => {                    # define object maps
            '*'   => 0,                     # don't call methods by default
            'foo' => 1,                     # do call foo() method
            'bar' => sub { ... },           # virtual method
        }
    );

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Factory> for locating and
loading template variable modules. Variable objects are subclasses of
L<Template::TT3::Variable> which acts as small, lightweight wrappers around
data values. They implement the additional behaviours that make TT variables
different from basic Perl variables.

It searches for variable modules in the following places:

    Template::TT3::Variable
    Template::Variable
    TemplateX::TT3::Variable
    TemplateX::Variable

For example, the C<text> variable type is mapped to the 
L<Template::TT3::Varaible::Text> object.

=head1 METHODS

The following methods are implemented or automatically added by the 
L<Template::TT3::Class::Factory> metaprogramming module in addition to 
those inherited from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.

=head2 variable($type)

Locates and loads a variable module and returns the class name. This is
created as an alias to the L<item()|Badger::Factory/item()> method in
L<Badger::Factory>. 

Note that the method doesn't automatically create a new variable object as
most factory modules do. TT uses this module to define constructor functions
(via the L<constructors()> method) which create objectm but not for creating
instances of the variable objects directly.

=head2 variables()

Method for inspecting or modifying the variable type that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head2 constructors(\%types)

Returns a reference to a hash array containing constructor functions for the
variables types specified as argument(s), along with any L<builtin()> variable
types.

    # default set of constructors
    my $ctors = Template::TT3::Variables->constructors;

    # customised set
    my $ctors = Template::TT3::Variables->constructors(
        undef => 'missing',                 # map data types
        text  => {                          # add virtual methods
            foo => sub { ... },             # to inbuilt data types
            bar => sub { ... },
        },
        'Wiz::Bang' => {                    # define custom object maps
            '*'   => 0,                     # don't call methods by default
            'foo' => 1,                     # do call foo() method
            'bar' => sub { ... },           # virtual method
        }
    );

=head1 INTERNAL METHODS

=head2 builtin()

This method loads all the builtin variable types and returns a reference
to a hash array mapping their internal names (e.g. C<text>, C<list>, etc)
to their external module names (e.g. L<Template::TT3::Variable::Text>,
L<Template::TT3::Variable::List>, etc).
    
=head2 found($type,$module)

This replaces the default method inherited from the L<Badger::Factory> base
class. Instead of automatically creating an object when the L<variable()>
method is called, it instead returns the class name of the module implementing
it.

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns. In this case it
is defined as C<variable>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Variable
    Template::Variable
    TemplateX::TT3::Variable
    TemplateX::Variable

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
L<Template::TT3::Variable>. See L<Template::TT3::Variable::Text>,
L<Template::TT3::Variable::List> and L<Template::TT3::Variable::Hash> for
examples.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

=head1 DESCRIPTION

