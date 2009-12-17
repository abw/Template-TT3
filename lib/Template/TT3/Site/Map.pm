package Template::TT3::Site::Map;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Base',
    accessors => 'data';

sub page {
    my ($self, $uri) = @_;
    
    # TODO: Decide if we want to cache the hash ref.  This way we get to
    # always return the same hash which will include any information added
    # by external agents.
    return $self->{ page }->{ $uri } ||= { };
}

1;
