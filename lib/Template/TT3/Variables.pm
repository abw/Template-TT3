package Template::TT3::Variables;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    import    => 'class',
    base      => 'Template::TT3::Base',
    constants => 'HASH CODE',
    messages  => {
        bad_type  => 'Invalid variable type for %s: %s',
        no_module => 'No module defined for variable type: %s',
    },
    constant  => {
        TYPES => 'Template::TT3::Types',
    };

use Template::TT3::Types;
our $TYPES = {
    UNDEF  => 'Template::TT3::Variable::Undef',
    TEXT   => 'Template::TT3::Variable::Text',
    HASH   => 'Template::TT3::Variable::Hash',
    ARRAY  => 'Template::TT3::Variable::List',
    CODE   => 'Template::TT3::Variable::Code',
    OBJECT => 'Template::TT3::Variable::Object',
};

sub init {
    my ($self, $config) = @_;
    my $types    = $self->class->hash_vars( TYPES => $config->{ types } );
    my $vmethods = $self->TYPES->vtables;
    my $ctors    = { 
        map {
            # load each module and call the constructor() method to generate
            # a typed variable constructor which we can call (in use_var()) 
            # to create variable instances of different types
            my $module = $types->{ $_ };
            my $config;
            
            $self->debug("$_ => $module") if DEBUG;
            
            if (ref $module eq HASH) {
                $config = $module;
                $module = $config->{ module }
                    || return $self->error_msg( no_module => $_ );
            }
            else {
                $config = { };
            }

            $_ => class($module)->load->name->constructor(
                variables => $self,
                methods   => $vmethods->{ $_ },
                %$config,
            );
        } 
        keys %$types
    };
    
    $self->{ data  } = $config->{ data } || { };
    $self->{ types } = $types;
    $self->{ ctors } = $ctors;
    $self->{ vars  } = { };
    return $self;
}

sub value {
    my ($self, $name, $element) = @_;
    my $var = $self->{ vars }->{ $name };

    # TODO: check for undef/missing values
    return ($var && $var->value)
        || $self->{ data }->{ $name };
}

# TODO: rename these get() set() and use()

sub var {
    my ($self, $name) = @_;

    $self->debug("var($name)") if DEBUG;
    
    return  $self->{ vars }->{ $name } 
        ||= $self->use_var( $name => $self->{ data }->{ $name } );
}

sub set_var {
    my ($self, $name, $value) = @_;

    $self->debug("var($name)") if DEBUG;
    
    # TODO: we currently don't update the target data, just the local
    # variable wrapper stored in $self->{ vars }
    return $self->{ vars }->{ $name } 
         = $self->use_var( $name => $value );

}


sub use_var {
    my ($self, $name, $value, $parent, $args, @more) = @_;
    my $ctor;

    TYPE_SWITCH: {
        $self->debug("use_var($name, $value)\n") if DEBUG;
        
        if (! defined $value) {
            $ctor = $self->{ ctors }->{ UNDEF }
                || return $self->error_msg( bad_type => $name, 'undef' );
        }
        elsif ($args && ref $value eq CODE) {
            $value = $value->(@$args);
            $self->debug(
                "evaluated CODE with args ", 
                $self->dump_data($args), 
                " => $value"
            ) if DEBUG;
            $args = undef;
            redo TYPE_SWITCH;
        }
        elsif (ref $value) {
            $ctor = $self->{ ctors }->{ ref $value } 
                 || $self->{ ctors }->{ OBJECT }
                 || return $self->error_msg( bad_type => $name, ref $value );
        }
        else {
            $ctor = $self->{ ctors }->{ TEXT }
                 || return $self->error_msg( bad_type => $name, 'value' );
        }
    }

    my $var = $ctor->($name, $value, $parent, $args, @more);
    
    $self->debug("use_var($name, $value) =>  [$var]") if DEBUG;
    
    return $var;
    
    return $ctor->($name, $value, $parent, $args, @more);
}

sub reset {
    my $self = shift;
    delete $self->{ vars };
}

1;

