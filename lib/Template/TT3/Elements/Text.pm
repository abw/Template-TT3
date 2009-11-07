#-----------------------------------------------------------------------
# Template::TT3::Element::Text - base class for literal text elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Text;

use Template::TT3::Elements::Literal;
use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    import    => 'class',
    constants => ':elem_slots',
    constant  => {
        SEXPR_FORMAT => '<text:%s>', 
    };


sub as_expr {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];        # don't use ${$_[1]} - aliasing problem
    return $self;
}


sub as_number {
    shift->todo;   # need to generate numerical assertion op
    $_[0];
}


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TOKEN],
    );
}


sub source {
    $_[0]->[TOKEN];
}


sub generate {
    $_[1]->generate_text(
        $_[0]->[TOKEN]
    );
}



#-----------------------------------------------------------------------
# Call on generate_text_ops() (in Template::TT3::Class) to create a 
# bunch of subclasses of Template::TT3::Element::Text.  See the comment
# for generate_number_ops() in Template::TT3::Elements::Number for 
# further discussion.  For text ops we alias the subroutine specified 
# as value(), values() and text().
#-----------------------------------------------------------------------

class->generate_text_ops(
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
    combine_set => infix_right => sub {                     # a ~= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->text($_[1])
          . $_[0]->[RHS]->text($_[1])
        );
    },
);


#-----------------------------------------------------------------------
# Special case for '~' which can be used as a prefix operator (forcing
# the RHS to be test, much in the same way that prefix '+' forces the
# RHS to be a number) or as an infix operator for string concatenation.
# [% ~foo;  foo ~ bar %]
#-----------------------------------------------------------------------

package Template::TT3::Element::Text::Squiggle;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element';

sub as_expr   { shift->become('txt_convert')->as_expr(@_) }
sub as_postop { shift->become('txt_combine')->as_postop(@_) }




#-----------------------------------------------------------------------
# Quoted strings.
#-----------------------------------------------------------------------


package Template::TT3::Element::Squote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_squote(
        $_[0]->[TOKEN],
    );
}


package Template::TT3::Element::Dquote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_dquote(
        $_[0]->[TOKEN],
    );
}

1;
