package Template::TT3::Element::Pod::Blank;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Terminator',
    view      => 'pod_blank',
#   view      => 'whitespace';
    alias     => {
        whitespace => 'self',
    };

1;