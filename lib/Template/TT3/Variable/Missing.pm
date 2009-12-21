package Template::TT3::Variable::Missing;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable::Undef',
    constant  => {
        type    => 'missing',
        defined => 0,
    },
    messages  => {
        bad_dot   => 'Invalid dot operation: <1>.<2> (<1> is missing)',
        undefined => '"%s" is missing',

    };

1;
