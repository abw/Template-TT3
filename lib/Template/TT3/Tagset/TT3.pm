package Template::TT3::Tagset::TT3;

use Template::TT3::Class
    version    => 2.71,
    base       => 'Template::TT3::Tagset';

our $TAGS = {
    inline => {
        start => '[%',
        end   => '%]',
    },
##    outline => {
#        start => qr/^%%/,
#    },
#    control => {
#        start => '[?',
#        end   => '?]',
#    },
#    comment => {
#        start => '[#',
#        end   => '#]',
#    }
    comment => '[# #]',
};

1;
