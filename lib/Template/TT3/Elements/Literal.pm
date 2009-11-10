#-----------------------------------------------------------------------
# Template::TT3::Element::Literal - base class for literal elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Literal;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element',
    constants  => ':elem_slots',
    alias      => {
        value  => \&text,
        values => \&text,
    },
    constant   => {
        SEXPR_FORMAT => '<literal:%s>',
    };

*source = \&text;

sub text {
    $_[0]->[TOKEN];
}

sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT,
        $_[0]->[TOKEN]
    );
}


sub generate {
    $_[1]->generate_literal(
        $_[0]->[TOKEN]
    );
}


sub dot_op {
    my ($self, $text, $pos, $rhs) = @_;
    $self->[META]->[ELEMS]->op(
        # $rhs should call method to resolve it as a dot-right-able item
        # in the same way that numerical_op() in T...Op::Number calls 
        # $rhs->number_op
        dot => $text, $pos, $self, $rhs
    );
}



# Word was here... maybe should be


#-----------------------------------------------------------------------
# Template::TT3::Element::Keyword - literal keyword elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Keyword;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_keyword(
        $_[0]->[TOKEN],
    );
}


1;
