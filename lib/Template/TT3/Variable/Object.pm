package Template::TT3::Variable::Object;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type    => 'object',
        PRIVATE => '_',
        PUBLIC  => '*',
    },
    messages => {
        denied => 'Access denied to object method: %s.%s',
    };

our $PRIVATE = qr/^_/;
our $METHODS = {
    '*' => 1,
    '_' => 0,
};

sub configuration {
    my ($self, $config) = @_;

    # provide default regex for matching private methods 
    $config->{ private } ||= $PRIVATE;

    # provide defaults for method lookup table
    my $methods = $config->{ methods } ||= { };
    
    while (my ($key, $value) = each %$METHODS) {
        $methods->{ $key } = $value
            unless exists $methods->{ $key };
    }
    
    $self->debug("config: ", $self->dump_data($config)) if DEBUG;
    
    return $config;
}

sub dot {
    my ($self, $name, $args) = @_;

    my $method 
        = $self->[META]->[METHODS]->{ $name }
       || $self->[META]->[METHODS]->{ 
            $name =~ $self->[META]->[CONFIG]->{ private } ? PRIVATE : PUBLIC
          }
       || return $self->error_msg( denied => $self->[NAME], $name );
              
    $method = $name if $method eq '1';

    $self->[META]->[VARS]->use_var( 
        $name,
        $self->[VALUE]->$method($args ? @$args : ()),
        $self, 
    );
}

    
1;
