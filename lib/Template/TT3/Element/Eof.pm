package Template::TT3::Element::Eof;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'eof',
    constant  => {
        eof   => 1,
    },
    alias     => {
        parse_expr => 'null',
    };


1;
