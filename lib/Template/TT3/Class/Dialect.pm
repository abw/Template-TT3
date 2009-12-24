package Template::TT3::Class::Dialect;

use Carp;
use Template::TT3::Class
    version    => 0.01,
    debug      => 0,
    uber       => 'Template::TT3::Class',
#    import     => 'class CLASS',
    constants  => 'ARRAY',
    modules    => 'DIALECT_MODULE',
    hooks      => {
#       grammar => \&grammar,
        scanner => \&scanner,
        tagset  => \&tagset,
        tags    => \&tags,
    };


# Before we do anything else we make the target class a subclass of
# Template::TT3::Dialect so that it inherits all of its goodness.

CLASS->export_before( 
    sub {
        my ($class, $target) = @_;
        return if $target eq 'Badger::Class';
        class($target, $class)
            ->base(DIALECT_MODULE);
    }
);


sub scanner {
    my ($self, $scanner) = @_;

    if (ref $scanner eq ARRAY) {
        $self->var( SCANNER_MODULE => $scanner->[0] );
        $self->var( SCANNER        => $scanner->[1] );
    }
    elsif (ref $scanner) {
        $self->var( SCANNER => $scanner );
    }
    else {
        $self->var( SCANNER_MODULE => $scanner );
    }
        
#    $self->base( DIALECT_MODULE );
}


sub tagset {
    my ($self, $tagset) = @_;

    if (ref $tagset eq ARRAY) {
        $self->var( TAGSET_MODULE => $tagset->[0] );
        $self->var( TAGSET        => $tagset->[1] );
    }
    elsif (ref $tagset) {
        $self->var( TAGSET => $tagset );
    }
    else {
        $self->var( TAGSET_MODULE => $tagset );
    }
        
    $self->base( DIALECT_MODULE );
}


sub tags {
    my ($self, $tags) = @_;
    $self->var( TAGS => $tags );
    $self->base( DIALECT_MODULE );
}


1;


=head1 NAME

Template::TT3::Class::Dialect - metaprogramming module for creating dialects

=head1 SYNOPSIS

    package TemplateX::Dialect::Example;
    
    use Template::TT3::Class::Dialect
        version => 3.14,
        debug   => 0,
        scanner => 'My::Scanner::Module',
        tagset  => 'My::Tagset::Module';

=head1 DESCRIPTION

This module implements a subclass of L<Badger::Class> that is specialised
for creating dialect modules.

=head1 USE OPTIONS

The following options can be specified when the
C<Template::TT3::Class::Dialect> module is loaded in addition to those
inherited from the L<Template::TT3::Class> and L<Badger::Class> base class
modules.

=head2 scanner

This option can be used to define either a scanner module that your dialect
should use, a set of configuration options for the default scanner, or both.

    # specifying a scanner module
    use Template::TT3::Class::Dialect
        scanner => 'My::Scanner::Module';
        
    # specifying scanner options
    use Template::TT3::Class::Dialect
        scanner => { 
            # scanner configuration options go here
        };
        
    # specifying scanner module and options
    use Template::TT3::Class::Dialect
        scanner => [
            'My::Scanner::Module', 
            { 
                # scanner configuration options go here
            }
        ];

The option is a shortcut for setting the
L<$SCANNER_MODULE|Template::TT3::Dialect/$SCANNER_MODULE> and/or 
L<$SCANNER|Template::TT3::Dialect/$SCANNER>
package variables which will have the same effect.

    our $SCANNER_MODULE = 'My::Scanner:Module';
    our $SCANNER = {
        # scanner configuration options go here
    };

=head2 tagset

This option can be used to define either a tagset module that your dialect
should use, a set of configuration options for the default tagset, or both. It
is similar to L<scanner> but sets the
L<$TAGSET_MODULE|Template::TT3::Dialect/$TAGSET_MODULE> and/or
L<$TAGSET|Template::TT3::Dialect/$TAGSET> package variables.

=head2 template

This option can be used to define the template modules that your dialect
should use.  It should probably allow you to also define options, but for
some reason it doesn't.  TODO: I need to look into that...

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Class> and L<Badger::Class> base class modules. 

=head2 scanner($config)

Method used to define a scanner module and/or configuration. See the
L<scanner> option.

=head2 tagset($config)

Method used to define a tagset module and/or configuration. See the L<tagset>
option.

=head2 template($module)

Method used to define the template module.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Class> and
L<Badger::Class> base class modules.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
