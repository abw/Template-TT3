package Template::TT3::Element::Command::Unless;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command::If',
    view       => 'unless',
    constants  => ':elements';

sub true {
    return ! $_[SELF]->[LHS]->value($_[CONTEXT]);
}



1;