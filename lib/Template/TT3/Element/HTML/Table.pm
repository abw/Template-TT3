package Template::TT3::Element::HTML::Table;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    as         => 'block_expr',
    constants  => ':elements',
    alias      => {
        value  => \&text,
        values => \&value,
    };


sub text {
    '<table>' . $_[SELF]->[BLOCK]->text( $_[CONTEXT] ) . '</table>';
}


1;