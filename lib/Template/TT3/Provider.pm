package Template::TT3::Provider;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Base';

sub fetch {
    shift->not_implemented('in provider base class');
}


1;

