package Template::TT3::Op::Variable;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op',
    constants => ':op_slots';


sub generate {
    $_[1]->generate_variable(
        $_[0]->[EXPR],
    );
}

1;
