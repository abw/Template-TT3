package Template::TT3::Op::VarNode;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op::Literal',
    constants => ':op_slots';


sub generate {
    $_[1]->generate_varnode(
        $_[0]->[EXPR],
        $_[0]->[ARGS],
    );
}

1;
