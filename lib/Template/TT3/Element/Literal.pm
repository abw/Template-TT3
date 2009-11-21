package Template::TT3::Element::Literal;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element',
    constants  => ':elements',
    as         => 'filename',
    view       => 'literal',
    constant   => {
        SEXPR_FORMAT => '<literal:%s>',
    },
    alias      => {
        name    => \&text,
        value   => \&text,
        values  => \&text,
        source  => \&text,
    };


sub parse_word {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    return $self;
}


sub text {
    $_[0]->[TOKEN];
}


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT,
        $_[0]->[TOKEN]
    );
}


sub old_generate {
    $_[1]->generate_literal(
        $_[0]->[TOKEN]
    );
}

1;

__END__

=head1 NAME

Template:TT3::Element::Construct - base class element for literal elements

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It acts as a
common base class for the L<Template::TT3::Element::Word>, L<Template::TT3::Element::Keyword>
and L<Template::TT3::Element::Keyword> modules.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 parse_word()

=head2 text()

=head2 value()

An alias to L<text()>.

=head2 values()

An alias to L<text()>.

=head2 name()

An alias to L<text()>.

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
L<Template::TT3::Element::Word>, 
L<Template::TT3::Element::Keyword>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
