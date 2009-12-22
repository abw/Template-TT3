package Template::TT3::Variable::Undef;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots DOT',
    constant  => {
        type    => 'undef',
        defined => 0,
    };


sub dot {
    my ($self, $name, $args, $element) = @_;
    
    $self->debug(
        "looking in vmethods for $name: ", 
        $self->dump_data($self->[META]->[METHODS])
    ) if DEBUG;
 
    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("undef vmethod: $name") if DEBUG;

        return $self->[CONTEXT]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
 
    return ($element || $self)
        ->fail( data_undef => $self->fullname );
}


sub text {
    my ($self, $element) = @_;

    $self->debug(
        "undef value() for $self->[NAME], ",
        "element is $element, ",
        "context is $self->[CONTEXT]"
    ) if DEBUG;

    # If we were passed an element reference then we raise the error 
    # against that so that it can decorate the exception with line 
    # number, source code, etc.  Otherwise we just throw a plain error.

    return ($element || $self)
        ->fail( data_undef => $self->fullname );
}

1;
