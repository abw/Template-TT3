package Template::TT3::Providers;

use Badger::Factory::Class
    version   => 3.00,
    debug     => 0,
    item      => 'provider',
    base      => 'Template::TT3::Base',
    path      => 'Template(X)::(TT3::|)Provider',
    providers => {
        default => 'Template::TT3::Provider::Cwd',
    };


1;

