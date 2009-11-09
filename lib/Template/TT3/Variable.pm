package Template::TT3::Variable;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    # Slot methods are read/write, but we want to make value() read only.  
    # So we use val() for the generated slot method and define value() below
    slots     => 'meta name val parent args',
    constants => ':type_slots',
    utils     => 'self_params',
    alias     => {
        value  => \&get,
        values => \&get,
    },
    messages  => {
        undefined  => '%s is undefined',
        no_vmethod => '"<2>" is not a valid <1> method in "<3>.<2>"', 
    };
        


# c'est n'est pas un constructor.  It *returns* a constructor, so it's a
# constructor constructor of sorts.

sub constructor {
    my ($self, $params) = self_params(@_);
    my $class   = ref $self || $self;
    my $config  = $self->configuration($params);
    my $vars    = $config->{ variables };       # TODO: or barf?  or use a proto?
    my $methods = $self->class->hash_vars( METHODS => $config->{ methods } );
    my $meta    = [$config, $vars, $methods];
    
    return sub {
#        $self->debug("args: ", $self->dump_data(\@_));
        bless [$meta, @_], $class;
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
    return $_[0]->[VALUE];
}


sub text {
    my $self  = shift;
    my $value = $self->[VALUE];

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
    ref $_[0]->[VALUE];
}

sub dot {
    shift->not_implemented;
}

sub apply {
    shift->not_implemented;
}

sub names {
    my $self  = shift;
    my @names = $self->[PARENT]
        ? ($self->[PARENT]->names, $self->[NAME])
        : ($self->[NAME]);

    return wantarray
        ?  @names
        : \@names;
}

sub fullname {
    join('.', shift->names);
}

sub variables {
    shift->[META]->[VARS];
}

sub methods {
    shift->[META]->[METHODS];
}

sub config {
    shift->[META]->[CONFIG];
}

sub method_names {
    keys %{ $_[0]->[META]->[METHODS] };
}

sub no_method {
    my ($self, $name) = @_;
    return $self->error_msg( 
        no_vmethod => $self->type => $name => $self->fullname,
#        join(', ', sort $self->method_names)
     );
}

1;
