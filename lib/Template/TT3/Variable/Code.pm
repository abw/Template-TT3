package Template::TT3::Variable::Code;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type  => 'code',
    },
    alias     => {
        apply => \&apply_scalar,
    };


sub apply_scalar {
    my $self = shift;
    $self->debug('apply_scalar(', join(', ', @_), ')') if DEBUG;
        
    $self->[CONTEXT]->use_var( 
        $self->[NAME], 
        scalar $self->[VALUE]->(@_), 
        $self,
    );
}

sub apply_list {
    my $self = shift;
    $self->debug('apply_list(', join(', ', @_), ')') if DEBUG;
        
    $self->[CONTEXT]->use_var( 
        $self->[NAME], 
        [ $self->[VALUE]->(@_) ],
        $self,
    );
}

sub text {
    my $self = shift;
    my $elem = shift;                   # FIXME - this is scary
    $self->debug('text()') if DEBUG;
    scalar $self->[VALUE]->(@_);
}


sub values {
    # this is called when a function appears in a text block... might 
    # as well call it
    $_[SELF]->debug('values()') if DEBUG;
    return ($_[SELF]->[VALUE]->());
}


sub dot {
    my ($self, $name, $args) = @_;

    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("code vmethod: $name") if DEBUG;
        return $self->[CONTEXT]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
    else {
        # TODO: should we automaticallly call the code?
        
        return $self->no_method($name);
    }
}


1;
