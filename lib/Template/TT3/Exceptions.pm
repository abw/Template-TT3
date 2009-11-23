package Template::TT3::Exceptions;

use Badger::Factory::Class
    version => 3.00,
    debug   => 0,
    item    => 'exception_obj',
    base    => 'Template::TT3::Base',
    path    => 'Template::TT3::Exception 
                Template::Exception 
                TemplateX::TT3::Exception
                TemplateX::Exception';

1;