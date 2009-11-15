package Template::TT3::Context;

use Template::TT3::Variables;
use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    constant    => {
        VARIABLES => 'Template::TT3::Variables',
    },
    accessors   => 'variables';


sub init {
    my ($self, $config) = @_;

    $self->{ variables } = $self->VARIABLES->new( 
        data => $config->{ variables },
    );
    
    return $self;
}


1;
