package Template::TT3::Variable::Hash;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type  => 'hash',
    };

sub dot {
    my ($self, $name, $args) = @_;

    $self->debug(
        "hash lookup $name with args [$args] => ", 
        $self->dump_data($args)
    ) if DEBUG;

    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("hash vmethod: $name") if DEBUG;
        return $self->[META]->[VARS]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
    else {
        return $self->[META]->[VARS]->use_var( 
            $name,
            $self->[VALUE]->{$name}, 
            $self, 
            $args
        );
    }
}



    
1;
