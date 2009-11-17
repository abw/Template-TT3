package Template::TT3::Context;

use Template::TT3::Variables;
use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    constant    => {
        VARIABLES => 'Template::TT3::Variables',
    },
    accessors   => 'variables scanner',
    messages    => {
        missing => '%s not found in context',
    };


sub init {
    my ($self, $config) = @_;

    $self->{ variables } = $self->VARIABLES->new( 
        data => $config->{ variables },
    );
    
    $self->{ scanner } = $config->{ scanner };
    $self->{ scope   } = $config->{ scope };
    
    return $self;
}


sub scope {
    my $self = shift;
    return $self->{ scope }
        || $self->error_msg( missing => 'scope' );
}
    
    

1;
