package Template::TT3::Tags;

use Badger::Factory::Class
    version   => 3.00,
    debug     => 0,
    item      => 'tag',
    base      => 'Template::TT3::Base',
    path      => 'Template(X)::(TT3::)Tag',
    tags      => {
        default => 'Template::TT3::Tag',
    };

1;

