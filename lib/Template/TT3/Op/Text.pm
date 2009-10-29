#========================================================================
#
# Template::TT3::Op::Text
#
# DESCRIPTION
#   Defines a number of classes to represent opcodes relating to numbers
#   and numerical operators like + - * / etc.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Op::Text;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op::Literal',
    constants => ':op_slots';

sub number_op {
    shift->todo;   # need to generate numerical assertion op
    $_[0];
}

sub generate {
    $_[1]->generate_text(
        $_[0]->[TEXT]
    );
}

1;
