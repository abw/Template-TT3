#-----------------------------------------------------------------------
# Template::TT3::Element::Literal - base class for literal elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Literal;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element',
    constants  => ':elements',
    as         => 'filename',
    constant   => {
        SEXPR_FORMAT => '<literal:%s>',
    },
    alias      => {
        name    => \&text,
        value   => \&text,
        values  => \&text,
        source  => \&text,
    };


sub text {
    $_[0]->[TOKEN];
}


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT,
        $_[0]->[TOKEN]
    );
}


sub view {
    $_[1]->view_literal($_[0]);
}


sub generate {
    $_[1]->generate_literal(
        $_[0]->[TOKEN]
    );
}


sub dot_op {
    shift->todo("I don't think this is used.  Is it?");
    
    my ($self, $text, $pos, $rhs) = @_;
    $self->[META]->[ELEMS]->op(
        # $rhs should call method to resolve it as a dot-right-able item
        # in the same way that numerical_op() in T...Op::Number calls 
        # $rhs->number_op
        dot => $text, $pos, $self, $rhs
    );
}


sub as_word {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    return $self;
}


#-----------------------------------------------------------------------
# Template::TT3::Element::Word - literal word elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Word;

use Template::TT3::Elements::Literal;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elements';


sub generate {
    $_[1]->generate_word(
        $_[0]->[TOKEN],
    );
}


sub view {
    $_[1]->view_word($_[0]);
}


sub as_expr {
    shift->become('variable')->as_expr(@_);
}


sub as_dotop {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    $self->debug("using $self->[TOKEN] as dotop: $self\n") if DEBUG;
    return $self;
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Keyword - literal keyword elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Keyword;

use Template::TT3::Class 
    debug     => 0,
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elements';


sub generate {
    $_[1]->generate_keyword(
        $_[0]->[TOKEN],
    );
}


sub view {
    $_[1]->view_keyword($_[0]);
}


sub as_dotop {
    # keywords downgrade themselves to simple words when used after a dot
    shift->become('word')->as_dotop(@_);
}


sub as_word {
    # keywords downgrade themselves to simple words when used after a dot
    shift->become('word')->as_word(@_);
}


#-----------------------------------------------------------------------
# Template::TT3::Element::Filename - literal filenames
#-----------------------------------------------------------------------

package Template::TT3::Element::Filename;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elements',
    as        => 'filename',        # mixin as_filename() role
    constant  => {
        SEXPR_FORMAT => '<filename:%s>',
    },
    alias      => {
        text   => \&filename,
        value  => \&filename,
        values => \&filename,
    };


sub generate {
    $_[1]->generate_filename(
        $_[0]->[EXPR],
    );
}


sub view {
    $_[1]->view_filename($_[0]);
}


sub sexpr {
    sprintf(
        $_[SELF]->SEXPR_FORMAT,
        $_[SELF]->[EXPR]
    )
}


1;
