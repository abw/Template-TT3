package Template::TT3::Element::Command::Do;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    as         => 'block_expr',
    constants  => ':elements',
    alias      => {
        text   => \&value,
        values => \&value,
    };


sub value {
    my @values = $_[SELF]->[BLOCK]->values($_[CONTEXT]);
    return pop @values;
}


1;
