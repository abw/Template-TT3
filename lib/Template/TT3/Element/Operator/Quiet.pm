#-----------------------------------------------------------------------
# Mixin class for binary assignment operators.  This adds a custom text() 
# method that calls the value() method but returns nothing.  This is how 
# we make the assignment expressions generate no output, e.g. [% a = 10 %].
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Quiet;

use Template::TT3::Class
    version   => 2.68,
    base      => 'Template::TT3::Element::Operator',
    constants => ':elements';

    
sub text {
    $_[SELF]->value($_[CONTEXT]);
    return ();
}


1;

