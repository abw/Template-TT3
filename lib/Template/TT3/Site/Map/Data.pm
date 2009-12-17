package Template::TT3::Site::Map::Data;

use Template::TT3::Class
    version => 2.71,
    debug   => 0,
    base    => 'Template::TT3::Site::Map';


sub init {
    my ($self, $config) = @_;
    $self->{ data } = $config;
    return $self;
}


1;
