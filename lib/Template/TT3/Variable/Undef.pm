package Template::TT3::Variable::Undef;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type  => 'undef',
    },
    messages  => {
        bad_dot => 'Invalid dot operation: <1>.<2> (<1> is undefined)',
    };


sub dot {
    my ($self, $name, $args) = @_;
 
    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("undef vmethod: $name") if DEBUG;

        return $self->[META]->[VARS]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
 
    return $self->error_msg( bad_dot => $self->fullname, $name );
}


sub value {
    my $self  = shift;
    return $self->error_msg( undefined => $self->fullname );
}


    
1;
