package Template::TT3::Element::Filename;

use Template::TT3::Class 
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elements',
    as        => 'filename',        # mixin parse_filename() role
    view      => 'filename',
    constant  => {
        SEXPR_FORMAT => '<filename:%s>',
    },
    alias      => {
        text   => \&filename,
        value  => \&filename,
        values => \&filename,
    };


sub template {
    my $self = shift;
    $self->fetch_template($self->[EXPR], @_);
}

sub sexpr {
    sprintf(
        $_[SELF]->SEXPR_FORMAT,
        $_[SELF]->[EXPR]
    )
}


1;

__END__

=head1 NAME

Template:TT3::Element::Filename - element representing a filename-like path

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It is used
to represent filenames.

=head1 METHODS

This module inherits all methods the L<Template::TT3::Element::Literal>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

=head2 TODO

Change this to URI, path, or something less filename-specific

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>,
L<Template::TT3::Base>,
L<Template::TT3::Element>,
L<Template::TT3::Element::Literal>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
