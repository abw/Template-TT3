package Template::TT3::Element::Command;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element',
    constants  => ':elem_slots :eval_args';


sub generate {
    $_[CONTEXT]->generate_keyword(
        $_[SELF]->[TOKEN],
    );
}

1;