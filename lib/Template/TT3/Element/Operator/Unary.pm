package Template::TT3::Element::Operator::Unary;

use Template::TT3::Class
    version   => 2.68,
    base      => 'Template::TT3::Element::Operator',
    view      => 'unary',
    constant  => {
        SOURCE_FORMAT => '%s%s', 
    };

1;
