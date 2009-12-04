package Template::TT3::Variable::Object;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots CODE',
    constant  => {
        type        => 'object',
        PRIVATE     => '_',
        PUBLIC      => '*',
        TT_PAIRS    => 'tt_pairs',
    },
    messages => {
        denied     => 'Access denied to object method: %s.%s',
        bad_method => 'Invalid object method called: %s.%s',
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
    $method = $self->[VALUE]->can($method)
        || return $self->error_msg( bad_method => $self->[NAME], $method )
            unless ref $method eq CODE;

    # TODO: How do we tell this to work in list context?
    my $result = $self->[VALUE]->$method($args ? @$args : ());

    $self->[CONTEXT]->use_var($name, $result, $self);
}


sub pairs {
    my ($self, $element) = @_;

    my $tt_pairs = $self->method(TT_PAIRS)
        || return $element
            ? $element->fail_pairs_bad
            : $self->error_msg( bad_pairs => $self->fullname );

    return $self->[VALUE]->$tt_pairs($self, $element);
}


sub method {
    my ($self, $name) = @_;
    my $method 
        = $self->[META]->[METHODS]->{ $name }
       || $self->[META]->[METHODS]->{ 
            $name =~ $self->[META]->[CONFIG]->{ private } ? PRIVATE : PUBLIC
          }
       || return;
              
    $method = $name if $method eq '1';

    return ref $method eq CODE
        ? $method
        : $self->[VALUE]->can($method);
}           


1;
