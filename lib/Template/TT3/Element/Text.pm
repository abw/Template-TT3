package Template::TT3::Element::Text;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    constant  => {
        SOURCE_FORMAT => '"%s"',
    };


1;