# NOTE: this is being replaced by Template::TT3::Exception::Data

package Template::TT3::Exception::Undef;

use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Exception::Syntax';
    
our $FORMAT = 'TT3 undefined data error at line <line> of <file>:<error><advice><source><marker>';


1;