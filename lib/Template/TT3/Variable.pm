package Template::TT3::Variable;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    slots     => 'variables methods config name value parent args',
    constants => ':type_slots',
    utils     => 'self_params',
    messages  => {
        undefined => '%s is undefined',
    };


# c'est n'est pas un constructor.  It *returns* a constructor, so it's a
# constructor constructor of sorts.

sub constructor {
    my ($self, $params) = self_params(@_);
    my $config  = $self->configuration($params);
    my $class   = ref $self || $self;
    my $vars    = $config->{ variables };       # TODO: or barf?  or use a proto?
    my $methods = $self->class->hash_vars( METHODS => $config->{ methods } );
    
    return sub {
#        $self->debug("args: ", $self->dump_data(\@_));
        bless [$vars, $methods, $config, @_], $class;
    };
}

sub configuration {
    $_[1];
}

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub get {
    return $_[0]->[VALUE_SLOT];
}

sub text {
    my $self  = shift;
    my $value = $self->[VALUE_SLOT];

    # NOTE: we shouldn't have to do this if undefined values are always
    # handled by T::TT3::Variable::Undef.  What about values that have been
    # set via set()?
    
    if (defined $value) {
        # TODO: check for non-text values, refs, etc
        return $value;
    }
    else {
        return $self->error_msg( undefined => $self->fullname );
    }
}

sub ref {
    ref $_[0]->[VALUE_SLOT];
}

sub dot {
    shift->not_implemented;
}

sub apply {
    shift->not_implemented;
}

sub names {
    my $self  = shift;
    my @names = $self->[PARENT_SLOT]
        ? ($self->[PARENT_SLOT]->names, $self->[NAME_SLOT])
        : ($self->[NAME_SLOT]);

    return wantarray
        ?  @names
        : \@names;
}

sub fullname {
    join('.', shift->names);
}

1;
