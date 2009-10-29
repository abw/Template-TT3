#========================================================================
#
# Template::TT3::Op::Literal
#
# DESCRIPTION
#   Defines a base class for opcode representing literal values.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Op::Literal;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op',
    constants => ':op_slots';


sub text {
    $_[0]->[TEXT];
}

sub value {
    $_[0]->[TEXT];
}

sub values {
    $_[0]->[TEXT];
}

sub text_op {
    $_[0];
}

sub dot_op {
    my ($self, $text, $pos, $rhs) = @_;
    $self->[META]->[OPS]->op(
        # $rhs should call method to resolve it as a dot-right-able item
        # in the same way that numerical_op() in T...Op::Number calls 
        # $rhs->number_op
        dot => $text, $pos, $self, $rhs
    );
}

1;
