package Template::TT3::Element::Assign;

use Template::TT3::Elements::Literal;
use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::InfixRight
                  Template::TT3::Element',
    import    => 'class',
    constants => ':elem_slots :eval_args',
    constant  => {
        SEXPR_FORMAT => '<assign:<%s><%s>>', 
    },
    alias     => {
        number => \&value,
        values => \&value,      # TODO: parallel assignment
    };


sub value {
#    $_[SELF]->debug("assign [$_[SELF]->[LHS]] [$_[SELF]->[RHS]]");
    $_[SELF]->[LHS]
            ->variable( $_[CONTEXT] )        # fetch LHS as a variable
            ->set(                           # set it to RHS value
                $_[SELF]->[RHS]->value( $_[CONTEXT] )
              )->value;
}


sub text {
    # when evaluated as text, e.g. [% a = 10 %], an assignment evaluates
    # itself but returns nothing.
    shift->value(@_);
    return ();
}

1;


