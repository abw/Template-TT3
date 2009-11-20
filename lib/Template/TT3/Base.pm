package Template::TT3::Base;

use Badger::Debug ':debug :dump';

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Base',
    constant  => {
        base_id => 'Template',
    };

1;
