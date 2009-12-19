package Template::TT3::Element::Operator::Range;

use Template::TT3::Elements::Operator;
use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::Infix',
    constants => ':elements BLANK';


sub text {
    join(
        BLANK, 
        @{ $_[SELF]->value($_[CONTEXT]) }
    );
}

sub values {
    @{ $_[SELF]->value($_[CONTEXT]) };
}

sub value {
    [ 
        $_[SELF]->[LHS]->number($_[CONTEXT])
     .. $_[SELF]->[RHS]->number($_[CONTEXT])
    ]
}

1;
