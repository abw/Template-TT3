package Template::TT3::Element::Word;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    view      => 'word',
    constants => ':elements',
    as        => 'pair';


sub parse_expr {
    # words become variables when requested as an expression
    shift->become('variable')->parse_expr(@_);
}


sub parse_dotop {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    $self->debug("using $self->[TOKEN] as dotop: $self\n") if DEBUG;
    return $self;
}


sub OLD_generate {
    $_[1]->generate_word(
        $_[0]->[TOKEN],
    );
}



1;

__END__

=head1 NAME

Template:TT3::Element::Word - element representing bare words

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> for
representing bare words.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Literal>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 parse_expr()

=head2 parse_dotop()

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
L<Template::TT3::Literal>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
