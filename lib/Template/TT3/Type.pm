#========================================================================
#
# Template::TT3::Type
#
# DESCRIPTION
#   Base class module for Template::Type::Text, List and Hash and 
#   any other virtual types you care to define.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Type;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    constants => 'HASH',
    constant  => {
        # tell Badger what class to strip off to generate id()
        base_id => __PACKAGE__,
        id      => 'type',
    },
    methods   => {
        # alias type() to id() method provided by Badger::Base
        type  => sub { $_[0]->id },
    };

our $METHODS = {
    new     => __PACKAGE__->can('new'),
    method  => \&method,       # TODO: can() as alias to method()?
    methods => \&methods,
    ref     => \&ref,
    hush    => \&hush,
};


sub init {
    my $self   = shift;
    my $config = @_ && ref $_[0] eq HASH ? shift : { @_ };
    @$self{ keys %$config } = values %$config;
    return $self;
}


sub methods {
    my $self = shift;
    return $self->class->hash_vars('METHODS');
}


sub method {
    my ($self, $name) = @_;
    my $methods = $self->methods;
    return $methods unless defined $name;
    return $methods->{ $name } 
        || $self->decline("method not found: $name");
}


sub ref {
    return CORE::ref($_[0]);
}


sub hush {
    return '';
}



1;

__END__

=head1 NAME

Template::TT3::Type - base class for Text, List and Hash objects

=head1 SYNOPSIS

    # defining a Thing subclass object
    package Template::TT3::Type::Thing;
    use base 'Template::TT3::Type';
    
    our $METHODS = {
        wibble => \&wibble,
        wobble => \&wobble,
    };
    
    sub wibble {
        my $self = shift;
        # some wibble code...
    }
    
    sub wobble {
        my $self = shift;
        # some wobble code...
    }

=head1 DESCRIPTION

The C<Template::TT3::Type> module implements a base class for the
L<Template::TT3::Type::Text>, L<Template::TT3::Type::List> and
L<Template::TT3::Type::Hash> virtual objects.  These implement the virtual 
methods that can be applied to text, list and hash items using
the dot operator:

    [% text = 'Hello World' %]
    [% text.length %]            # 11

    [% list = [10, 20, 30] %]
    [% list.size %]              # 3

    [% hash = { x=10, y=20 } %]
    [% hash.size %]              # 2

They can also be used to create objects for those who prefer
to do things in a stricter object-oriented style.

    [% text = Text.new('Hello World')  %]
    [% list = List.new(10, 20, 30)     %]
    [% hash = Hash.new(x = 10, y = 20) %]

=head1 METHODS

The following methods are defined in addition to those inherited from 
L<Template::TT3::Base> and L<Badger::Base>.

=head2 init(\%config)

Initialialisation method to handle any per-object initialisation. This is
called by the L<new()|Badger::Base/new()> method inherited from
L<Badger::Base> . In this base class, the method simply copies all items in
the C<$config> hash array into the C<$self> object.

This method can also be called directly to add any further items to
the object.  Named parameters can be provided as a list or by
reference to a hash array, as per the L<new()|Badger::Base/new()> method.

    $object->init( phi => 1.618 );

=head2 clone()

Create a copy of the current object.

    my $clone = $object->clone();

Additional named parameters can be provided.  These are merged with
the items defined in the parent object and passed to the cloned
object's L<init()> method.

    my $clone = $object->clone( g => 0.577 );

=head2 methods()

Returns a reference to a hash array containing the content of the
C<$METHODS> package variable in the current class and any base classes.

    my $methods = $object->methods;

=head2 method($name)

Returns a reference to a particular method from the hash reference 
returned by the L<methods()> method.

    my $method = $object->method('ref');


When called without any arguments, it returns a reference to the
entire hash reference, as per L<methods()>.

    my $method = $object->method->{ foo };

=head2 ref()

Returns the name of the object type, e.g. C<Template::TT3::Type>,
C<Template::TT3::Type::Text>, L<Template::TT3::Type::List>, etc., exactly as
Perl's C<ref()> function does.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2008 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

L<Template::TT3::Type::Text>, L<Template::TT3::Type::List> and L<Template::TT3::Type::Hash>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


