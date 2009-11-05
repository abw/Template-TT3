package Template::TT3::Element::Squote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_squote(
        $_[0]->[TEXT],
    );
}

package Template::TT3::Element::Dquote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_dquote(
        $_[0]->[TEXT],
    );
}

1;
