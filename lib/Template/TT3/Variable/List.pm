package Template::TT3::Variable::List;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    utils     => 'numlike',
    constants => ':type_slots',
    constant  => {
        type  => 'list',
    },
    alias     => {
        pairs => \&values,
    };
    

sub dot {
    my ($self, $name, $args) = @_;

    if (numlike $name) {
        $self->debug("numerical list index: $name") if DEBUG;
        return $self->[CONTEXT]->use_var( 
            $name,
            $self->[VALUE]->[$name], 
            $self, 
            $args
        );
    }
    elsif (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("list vmethod: $name") if DEBUG;
        return $self->[CONTEXT]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
    else {
        return $self->no_method($name);
    }
}

sub dot_set {
    my ($self, $name, $value, $element) = @_;

    $self->debug(
        $self->fullname, "->dot_set($name => $value) ", 
        $element ? " by element $element" : " (no element)"
    ) if DEBUG;
    
    $self->[VALUE]->[$name] = $value;

    return $self->[CONTEXT]->use_var( 
        $name,
        $value, 
        $self, 
    );
}


sub values {
    $_[SELF]->debug("values()") if DEBUG;
    return @{ $_[SELF]->[VALUE] };
}


1;

