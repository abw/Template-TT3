package Template::TT3::Element::Command::Raw;

use Template::TT3::Class
    version    => 3.00,
    base       => 'Template::TT3::Element::Keyword',
    as         => 'block_expr',
    view       => 'raw',
    constants  => ':elements',
    alias      => {
        value  => \&text,
        values => \&text,
    };

sub text {
    $_[SELF]->[BLOCK]->text( $_[CONTEXT] );
}

1;
