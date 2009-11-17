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
    view      => 'text',
    constants => ':elem_slots :eval_args',
    constant  => {
        SEXPR_FORMAT  => '<text:%s>', 
        SOURCE_FORMAT => "'%s'",
    };


# TODO: check this isn't being inherited by text ops below...

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
    # TODO: escape single quotes...
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[TOKEN]
    );
}


sub generate {
    $_[1]->generate_text(
        $_[0]->[TOKEN]
    );
}


sub variable {
    # text can be converted to a text variable in order to perform dotops on it
    $_[CONTEXT]->{ variables }
         ->use_var( $_[SELF], $_[SELF]->text( $_[CONTEXT] ) );
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
);


#-----------------------------------------------------------------------
# A call to generate_text_assign_ops() which performs much the same 
# task with the exception that it doesn't alias the function to the 
# text() method.  Instead we inherit the text() method from the 
# T::TT3::Element::Operator::Assignment base class which performs the 
# assignment (by calling $self->value()) but returns an empty list.
# This is how we silence assignment operators from generating any output
# in "text context", e.g. [% a = 10 %]
#-----------------------------------------------------------------------

class->generate_text_assign_ops(
    combine_set => infix_right => assignment => sub {       # a ~= b
        return $_[0]->[LHS]->assign(
            $_[1], 
            $_[0]->[LHS]->text($_[1])
          . $_[0]->[RHS]->text($_[1])
        );
    },
);



#-----------------------------------------------------------------------
# Another call to generate_pre_post_ops() which defines operator classes
# that can be either prefix operators or postfix operators.  e.g. '~'
#-----------------------------------------------------------------------

class->generate_pre_post_ops(
    squiggle => ['txt_convert', 'txt_combine'],
);




#-----------------------------------------------------------------------
# Template::TT3::Element::Padding - a thin subclass of the text element
# used to represent sythesised text tokens added as part of the scanning
# process.  For example, the '=' pre and post chomp flags collapse any
# preceding/following text to a single space.  We save the original 
# whitespace (of which there may be none) as a whitespace token and add
# new padding token of a single space.  When we want to re-generate the 
# original template source we print out the whitespace but ignore padding.
# OTOH, when we're parsing we ignore whitespace but include padding as
# kind of text expression.
#-----------------------------------------------------------------------

package Template::TT3::Element::Padding;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots',
    constant  => {
        SEXPR_FORMAT  => '<padding:%s>', 
    };

sub generate {
    $_[1]->generate_padding(
        $_[0]->[TOKEN]
    );
}


#-----------------------------------------------------------------------
# Quoted strings.
#-----------------------------------------------------------------------

package Template::TT3::Element::String;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub as_expr {
    my ($self, $token, $scope, $prec) = @_;
    
    # advance token
    $$token = $self->[NEXT];
    
    # strings can be followed by postops (postfix and infix operators)
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}

sub variable {
    # TODO: fixme so I'm not re-creating single quotes each time
    $_[1]->{ variables }
         ->use_var( "'" . $_[0]->[TOKEN] . "'", $_[0]->[TOKEN] );
}




package Template::TT3::Element::Squote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::String',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_squote(
        $_[0]->[TOKEN],
    );
}


package Template::TT3::Element::Dquote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::String',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_dquote(
        $_[0]->[TOKEN],
    );
}

1;
