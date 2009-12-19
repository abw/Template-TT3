package Template::TT3::Element::Operator::Boolean;

use Template::TT3::Elements::Operator;
use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    import    => 'class';


#-----------------------------------------------------------------------
# Call on generate_elements() (in Template::TT3::Class::Element) to 
# create a bunch of subclasses of Template::TT3::Element::Operator::Text.
# See the comments in Template::TT3::Elements::Operator::Number for 
# further discussion.  For boolean ops we alias the subroutine specified 
# as value() and values().  We inherit the default text() method from 
# the element base class.
#-----------------------------------------------------------------------

class->generate_elements(
    {
        methods => 'value values' 
    },
    'not' => prefix => sub {                                # ! a
        return 
            ! $_[0]->[RHS]->value($_[1])
    },
    'and' => infix_left => sub {                            # a && b
        return $_[0]->[LHS]->value($_[1])
            && $_[0]->[RHS]->value($_[1])
    },
    'or' => infix_left => sub {                             # a || b
        return $_[0]->[LHS]->value($_[1])
            || $_[0]->[RHS]->value($_[1])
    },
    'nor' => infix_left => sub {                            # a !! b
        my $value = $_[0]->[LHS]->value($_[1]);
        return defined $value
            ? $value
            : $_[0]->[RHS]->value($_[1])
    },
    and_set => infix_right => assignment => sub {           # a &&= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->value($_[1])
         && $_[0]->[RHS]->value($_[1])
        )->value;
    },
    or_set => infix_right => assignment => sub {            # a ||= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->value($_[1])
         || $_[0]->[RHS]->value($_[1])
        )->value;
    },
    nor_set => infix_right => assignment => sub {           # a !!= b
        my $value = $_[0]->[LHS]->value($_[1]);
        return defined $value
            ? $value
            : $_[0]->[LHS]->assign(
                  $_[1], 
                  $_[0]->[RHS]->value($_[1])
              )->value;
    },
);


1;
