package Template::TT3::Element::Terminator;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'terminator',
    alias     => {
        parse_expr  => 'null',
        parse_body  => 'null',
        parse_infix => 'reject',
        terminator  => 'next_skip_ws',
    };

1;
