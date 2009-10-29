package Template::TT3::Op::Binop;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op',
    constants => ':op_slots';


sub generate {
    $_[1]->generate_binop(
        $_[0]->[TEXT],
        $_[0]->[LHS], 
        $_[0]->[RHS]
    );
}


1;
