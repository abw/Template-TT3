package Template::TT3::Variable::List;

use Template::TT3::Class
    version   => 0.01,
    base      => 'Template::TT3::Variable',
    utils     => 'numlike',
    constants => ':type_slots',
    messages  => {
        bad_index => 'Invalid list index: <1>.<2> (<2> is not a number)',
    };

sub dot {
    my ($self, $name, $args) = @_;

    return $self->error_msg( bad_index => $self->fullname, $name )
        unless numlike $name;
        
    $self->[META]->[VARS]->use_var( 
        $name,
        $self->[VALUE]->[$name], 
        $self, 
        $args
    );
}

1;

