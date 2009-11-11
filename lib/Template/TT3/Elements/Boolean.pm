package Template::TT3::Element::Boolean;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    import    => 'class',
    constants => ':elem_slots';


#-----------------------------------------------------------------------
# Call on generate_bool_ops() (in Template::TT3::Class) to create a 
# bunch of subclasses of Template::TT3::Element::Boolean.  See the comment
# for generate_number_ops() in Template::TT3::Elements::Number for 
# further discussion.  For boolean ops we alias the subroutine specified 
# as value() and values().
#-----------------------------------------------------------------------

class->generate_boolean_ops(
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
