package Template::TT3::Variable::Hash;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots';

sub dot {
    my ($self, $name, $args) = @_;

    $self->debug(
        "hash lookup $name with args [$args] => ", 
        $self->dump_data($args)
    ) if DEBUG;

    $self->[META]->[VARS]->use_var( 
        $name,
        $self->[VALUE]->{$name}, 
        $self, 
        $args
    );
}



    
1;
