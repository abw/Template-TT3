package Template::TT3::Op::Ident;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op::Literal',
    constants => ':op_slots';


sub generate {
    $_[0]->[TEXT]
}

1;
