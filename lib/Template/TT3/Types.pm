#========================================================================
#
# Template::TT3::Types
#
# DESCRIPTION
#   Factory module for loading and instantiating Template::TT3::Type objects
#   on demand.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Types;

use Badger::Factory::Class
    version => 3.00,
    debug   => 0,
    item    => 'type',
    base    => 'Template::TT3::Base',
    path    => 'Template::TT3::Type',
    types   => {
        # Perl's names, and our made-up names to map different data types
        # to method providers
        UNDEF  => 'Template::TT3::Type::Undef',
        TEXT   => 'Template::TT3::Type::Text',
        ARRAY  => 'Template::TT3::Type::List',
        HASH   => 'Template::TT3::Type::Hash',
        CODE   => 'Template::TT3::Type::Code',
#       OBJECT => 'Template::TT3::Type::Object',
        
        # lower case TT names
#        text   => 'Template::TT3::Type::Text',
#        list   => 'Template::TT3::Type::List',
#        hash   => 'Template::TT3::Type::Hash',
#       params => 'Template::TT3::Type::Params',
    };

our $STANDARD_TYPES = [qw( UNDEF VALUE ARRAY HASH CODE OBJECT )];
our $VTABLES = { };

sub OLD_init {
    my ($self, $config) = @_;
#    $self->{ types } = $self->class->hash_vars( TYPES => $config->{ types } );
    $self->init_factory($config);
    return $self;
}

sub TMP_init {
    my ($self, $config) = @_;
    $self->init_factory($config);
#    $self->debug("types: ", $self->dump_data($self->{ types }));
    return $self;
}


sub preload {
    my $self  = shift->prototype;
    my $types = $self->types;
    my $loads = { };
    
    $self->debug("preload() types: ", $self->dump_data($types)) if DEBUG;
    
    foreach my $type (keys %$types) {
        $loads->{ $type } = $self->type($type);
        $self->debug("preload $type => ", $loads->{ $type }) if DEBUG;
    }
    
    return $loads;
}


sub vtables {
    my $self  = shift->prototype;
    my $types = $self->preload;
    $self->debug("vtables() types: ", $self->dump_data($types)) if DEBUG;
    return {
        map {
            my $k = $_;
            my $t = $types->{ $k };
            ($_, $VTABLES->{ $t } ||= $self->type($k)->methods);
        }
        keys %$types
    };
}


sub found {
    my ($self, $type, $module) = @_;
    return $self->load($module);
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

Template::TT3::Types - factory for creating text, hash, list and other objects

=head1 SYNOPSIS

    use Template::TT3::Types;

    my $text = Template::TT3::Types->object( text => 'Hello World' );
    print "text is ", $text->length(), " characters long\n";    

    my $list = Template::TT3::Types->object( list => [ 'Hello', 'World' ] );
    print "list has ", $list->size(), " items\n";    

    my $hash = Template::TT3::Types->object( hash => { Hello => 'World' } );
    print "hash has ", $hash->size(), " pairs\n";    

=head1 DESCRIPTION

This module implements a factory for creating Template::TT3::Type objects.
The three basic object types are C<text>, C<list> and C<hash>, implemented
by Template::TT3::Type::Text, Template::TT3::Type::List and Template::TT3::Type::Hash
respectively.

TODO

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 VERSION

$Revision: 1.2 $

=head1 COPYRIGHT

Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


