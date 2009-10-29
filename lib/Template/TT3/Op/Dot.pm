#========================================================================
#
# Template::TT3::Op::Dot
#
# DESCRIPTION
#   Opcode representing the dot operator.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Op::Dot;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op',
    constants => ':op_slots';


sub generate {
    $_[1]->generate_dot(
        $_[0]->[LHS], 
        $_[0]->[RHS]
    );
}

1;
