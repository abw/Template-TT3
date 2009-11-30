package Template::TT3::Factory::Class;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    uber      => 'Badger::Factory::Class',
    constant  => {
        FACTORY => 'Template::TT3::Factory',
    };

1;
