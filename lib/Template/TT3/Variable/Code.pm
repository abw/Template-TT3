package Template::TT3::Variable::Code;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots :eval_args',
    alias     => {
        apply => \&apply_scalar,
    },
    messages  => {
    };

sub apply_scalar {
    my $self = shift;
    $self->debug('apply_scalar(', join(', ', @_), ')') if DEBUG;
        
    $self->[META]->[VARS]->use_var( 
        $self->[NAME], 
        scalar $self->[VALUE]->(@_), 
        $self,
    );
}

sub apply_list {
    my $self = shift;
    $self->debug('apply_list(', join(', ', @_), ')') if DEBUG;
        
    $self->[META]->[VARS]->use_var( 
        $self->[NAME], 
        [ $self->[VALUE]->(@_) ],
        $self,
    );
}

sub text {
    my $self = shift;
    $self->debug('text()') if DEBUG;
    scalar $self->[VALUE]->(@_);
}

sub OLD_list {
    return shift->apply_list(@_);
    # [ $_[SELF]->[VALUE]->() ];
}

sub values {
    # this is called when a function appears in a text block... might 
    # as well call it
    $_[SELF]->debug('values()') if DEBUG;
    return ($_[SELF]->[VALUE]->());
}


1;
