#-----------------------------------------------------------------------
# Template::TT3::Element::Text - base class for literal text elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Text;

use Template::TT3::Elements::Literal;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots',
    constant  => {
        SEXPR_FORMAT => '<text:%s>', 
    };


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TEXT],
    );
}


sub source {
    $_[0]->[TEXT];
}


sub as_number {
    shift->todo;   # need to generate numerical assertion op
    $_[0];
}


sub generate {
    $_[1]->generate_text(
        $_[0]->[TEXT]
    );
}

sub as_expr {
    my ($self, $token) = @_;
    $$token = $self->[NEXT];
    return $self;

# this breaks things - I guess it's an aliasing problem...
#    ${$_[1]} = $_[0]->[NEXT];     # advance token
#    return $_[0];

    # explicit way
 #   my ($self, $token) = @_;
 #   $self->debug('looking for text as_expr()');
 #   $$token = $self->[NEXT];     # advance token
 #   return $self;
}


package Template::TT3::Element::Squote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_squote(
        $_[0]->[TEXT],
    );
}


package Template::TT3::Element::Dquote;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Text',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_dquote(
        $_[0]->[TEXT],
    );
}

1;
