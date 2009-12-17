package Template::TT3::Variable::Undef;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type  => 'undef',
    },
    alias     => {
        text   => \&value,
        values => \&value,
    },
    messages  => {
        # this is backup in case we don't have an $element passed to us
        bad_dot => 'Invalid dot operation: <1>.<2> (<1> is undefined)',
    };


sub dot {
    my ($self, $name, $args, $element) = @_;
 
    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("undef vmethod: $name") if DEBUG;

        return $self->[CONTEXT]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
 
    return $element
        ? $element->fail_undef_dot( $self->fullname, $name )
        : $self->error_msg( bad_dot => $self->fullname, $name );

#    return $self->error_msg( bad_dot => $self->fullname, $name );
}


sub value {
    my ($self, $element) = @_;

    # If we were passed an element reference then we raise the error 
    # against that so that it can decorate the exception with line 
    # number, source code, etc.  Otherwise we just throw a plain error.
    $self->debug("undef value() for $self->[NAME], element is $element, context is $self->[CONTEXT]") if DEBUG;
    return $element
        ? $element->fail_undef_data #( $self->fullname )
        : $self->error_msg( undefined => $self->fullname );
}


    
1;
