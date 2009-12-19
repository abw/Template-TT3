package Template::TT3::Types;

use Template::TT3::Class::Factory
    version => 2.69,
    debug   => 0,
    item    => 'type',
    path    => 'Template(X)::(TT3::|)Type',
    names   => {
        TEXT  => 'text',
        CODE  => 'code',
        ARRAY => 'list',
        HASH  => 'hash',
        UNDEF => 'undef',
    };

our @STANDARD_TYPES = qw( TEXT CODE ARRAY HASH CODE UNDEF );
our $VTABLES = { };


sub preload {
    my $self  = shift->prototype;
    my $types = $self->types;
    my $loads = { };

    # all change
    $types = $TYPE_NAMES;
    
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


