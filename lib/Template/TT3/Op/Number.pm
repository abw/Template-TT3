#========================================================================
#
# Template::TT3::Op::Number
#
# DESCRIPTION
#   Defines a number of classes to represent opcodes relating to numbers
#   and numerical operators like + - * / etc.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Op::Number;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op::Literal',
    constants => ':op_slots';


sub number_op {
    $_[0];
}

# numerical_binary_op() / num_bin_op()

sub numerical_op {
    my ($self, $type, $text, $pos, $rhs) = @_;
    $self->[META]->[OPS]->op(
        $type, $text, $pos, $self, $rhs->number_op
    );
}

sub generate {
    $_[1]->generate_number(
        $_[0]->[TEXT]
    );
}

1;
