package Template::TT3::Exception::Resource;

use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Exception::Syntax';
    
our $FORMAT = 'TT3 resource error at line <line> of <file>:<error><advice><source><marker>';


1;