package Template::TT3::Tagset::TT3;

use Template::TT3::Class
    version    => 2.71,
    base       => 'Template::TT3::Tagset';

our $TAGS = {
    inline  => {
        start => '[%', 
        end   => '%]',
    },
    outline => {                
        type    => 'default',       # doesn't have a subclass of it's own so 
        start   => qr/^%%/m,        # it uses Template::TT3::Tag
        end     => qr/(\n|$)/m ,
    },
    comment => {
        start   => '[#',
        end     => '#]',
    },
    control => {
        start => '[?',
        end   => '?]',
    },
};

1;
