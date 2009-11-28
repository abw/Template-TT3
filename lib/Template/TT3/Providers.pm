package Template::TT3::Providers;

use Badger::Factory::Class
    version   => 3.00,
    debug     => 0,
    item      => 'provider',
    base      => 'Template::TT3::Base',
    path      => 'Template::TT3::Provider Template::Provider::ButNotYet
                  TemplateX::TT3::Provider TemplateX::Provider',
    providers => {
        default => 'Template::TT3::Provider::File',
    };


1;

