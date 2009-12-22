package Template::TT3::Element::Command::Unless;

use Template::TT3::Class::Element
    version    => 2.68,
    debug      => 0,
    base       => 'Template::TT3::Element::Command::If',
    view       => 'unless';


sub true {
    return ! $_[SELF]->[LHS]->value($_[CONTEXT]);
}


1;