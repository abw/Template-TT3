package Template::TT3::Element::Filename;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    roles     => 'filename',        # mixin parse_filename() role
    view      => 'filename',
    alias      => {
        text   => \&filename,
        value  => \&filename,
        values => \&filename,
    };


sub template {
    my $self = shift;
    $self->fetch_template($self->[EXPR], @_);
}


sub source {
    shift->filename;
}


1;

__END__

=head1 NAME

Template:TT3::Element::Filename - element representing a filename-like path

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> used
to represent filenames.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes, and the 
L<Template::TT3::Element::Role::Filename> mix-in role.

=head2 parse_filename($token)

This method is called when an element appears where a filename is expected.
It concatenates the text of any other filename tokens that follow immediately
after it and stores it internally.

=head2 filename()

This method returns the filename parsed by L<parse_filename()>.

=head2 text()

An alias to the L<filename()> method.

=head2 value()

An alias to the L<filename()> method.

=head2 values()

An alias to the L<filename()> method.

=head2 template($context)

The methods returns a L<template|Template::TT3::Template> object corresponding
to the filename stored in the element.

=head2 source()

This method returns the source code for the element (i.e. the filename).

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_filename()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the C<view_filename()>
method.

=head2 TODO

Change this to URI, path, or something less filename-specific

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element::Literal>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes. It also mixes in methods from the
L<Template::TT3::Element::Role::Filename> module.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
