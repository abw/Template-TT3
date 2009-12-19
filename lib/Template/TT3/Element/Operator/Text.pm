package Template::TT3::Element::Operator::Text;

use Template::TT3::Elements::Operator;          # FIXME
use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',      # TODO: +Operator
    import    => 'class';


sub variable {
    # text operation can be converted to a text variable in order to 
    # perform dotops on it
    $_[CONTEXT]->use_var( 
        $_[SELF], $_[SELF]->text( $_[CONTEXT] ) 
    );
}


#-----------------------------------------------------------------------
# Call on generate_elements() (in Template::TT3::Class::Element) to 
# create a bunch of subclasses of Template::TT3::Element::Operator::Text.
# See the comments in Template::TT3::Elements::Operator::Number for 
# further discussion.  For text ops we alias the subroutine specified 
# as value(), values() and text().
#-----------------------------------------------------------------------

class->generate_elements(
    {
        methods => 'text value values' 
    },

    convert => prefix => sub {                              # ~ b
        return $_[0]->[EXPR]->text($_[1])
    },
    combine => infix_left => sub {                          # a ~ b
        return $_[0]->[LHS]->text($_[1])
             . $_[0]->[RHS]->text($_[1])
    },
    equal => infix => sub {
        return $_[0]->[LHS]->text($_[1])                    # a eq b
            eq $_[0]->[RHS]->text($_[1])
    },
    not_equal => infix => sub {                             # a ne b
        return $_[0]->[LHS]->text($_[1])
            ne $_[0]->[RHS]->text($_[1])
    },
    less_than => infix => sub {                             # a lt b
        return $_[0]->[LHS]->text($_[1])
            lt $_[0]->[RHS]->text($_[1])
    },
    more_than => infix => sub {                             # a gt b
        return $_[0]->[LHS]->text($_[1])
            gt $_[0]->[RHS]->text($_[1])
    },
    less_equal => infix => sub {                            # a lt b
        return $_[0]->[LHS]->text($_[1])
            le $_[0]->[RHS]->text($_[1])
    },
    more_equal => infix => sub {                            # a ge b
        return $_[0]->[LHS]->text($_[1])
            ge $_[0]->[RHS]->text($_[1])
    },
    compare => infix => sub {                               # a cmp b
        return $_[0]->[LHS]->text($_[1])
           cmp $_[0]->[RHS]->text($_[1])
    },
);


#-----------------------------------------------------------------------
# Same again, but without aliasing the function to the text() method.  
# Instead we inherit the text() method from the T~Operator::Assignment 
# base class which performs the assignment (by calling $self->value()) 
# but returns an empty list. This is how we silence assignment operators 
# from generating any output in "text context", e.g. [% a = 10 %]
#-----------------------------------------------------------------------

class->generate_elements(
    {   
        methods => 'value values' 
    },

    combine_set => infix_right => assignment => sub {       # a ~= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->text($_[1])
          . $_[0]->[RHS]->text($_[1])
        );
    },
);


#-----------------------------------------------------------------------
# A call to generate_pre_post_ops() which defines operator classes
# that can be either prefix operators or postfix operators.  e.g. '~'
#-----------------------------------------------------------------------

class->generate_pre_post_ops(
    squiggle => ['txt_convert', 'txt_combine'],
);

1;
