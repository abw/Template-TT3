package Template::TT3::Context;

use Template::TT3::Variables;
use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    import      => 'class',
    accessors   => 'variables scanner parent lookup',
    utils       => 'self_params',
    constants   => 'HASH CODE',
    constant    => {
        VARIABLES   => 'Template::TT3::Variables',
    },
    messages    => {
        bad_type    => 'Invalid variable type for %s: %s',
        missing     => '%s not found in context',
    };


sub init {
    my ($self, $config) = @_;

    my $vars = $self->VARIABLES->new($config);

    $self->{ VARS  } = $vars;
    $self->{ types } = $vars->types;
    $self->{ type  } = $vars->constructors;
    $self->{ data  } = $config->{ data } || { };
    
    $self->debug("context init: ", $self->dump_data($self)) if DEBUG;
    
#    $self->{ variables } = $self->VARIABLES->new( 
#        data => $config->{ variables },
#    );
    
    $self->{ scanner } = $config->{ scanner };
    $self->{ scope   } = $config->{ scope };
    
    return $self;
}


sub var {
    my $self = shift;

    return @_ > 1
        ? $self->set_var(@_)
        : $self->{ vars }->{ $_[0] } 
      ||= $self->get_var(@_);
}


sub get_var {
    my ($self, $name, $context) = @_;
    my $value;

    # If we need to lookup a variable in a parent context then we pass the
    # child context as an argument so that the parent creates a new variable
    # bound to the child context, not the parent.  Otherwise we use $self.
    $context ||= $self;

    $self->debug("get_var($name)") if DEBUG;

    if (exists $self->{ data }->{ $name }) {
        $self->debug("found $name in data: $self->{ data }->{ $name }") 
            if DEBUG;
            
        return $context->use_var( 
            $name => $self->{ data }->{ $name } 
        );
    }
    elsif ($self->{ auto_var } 
       && defined ($value = $self->{ auto_var }->($self, $name))) {
        $self->debug("got $name from auto handler: $value") 
            if DEBUG;

        return $context->use_var( 
            $name => $value 
        );
    }
    elsif ($self->{ lookup }) {
        $self->debug("asking lookup for $name") if DEBUG;
        return $self->{ lookup }->get_var($name, $self);
    }
    else {
        $self->debug("$name is missing") if DEBUG;
        return $self->no_var($name);
    }
}
        
    
sub set_var {
    my ($self, $name, $value) = @_;

    $self->debug("set_var($name, $value)") if DEBUG;
    
    # we don't update the target data, just the local variable wrapper
    return $self->{ vars }->{ $name } 
         = $self->use_var( $name => $value );
}


sub set_vars {
    my ($self, $params) = self_params(@_);
    my $vars = $self->{ vars };
#    my $VARS = $self->{ VARS };
    
    while (my ($name, $value) = each %$params) {
#        $vars->{ $name } = $VARS->variable( $name => $value );
        $vars->{ $name } = $self->use_var( $name => $value );
    }
}


sub use_var {
    my ($self, $name, $value, $parent, $args, @more) = @_;
    my $ctor;

    TYPE_SWITCH: {
        $self->debug("var($name, $value)") if DEBUG;
        
        if (! defined $value) {
            $self->debug("value is undefined") if DEBUG;
            
            $ctor = $self->{ type }->{ UNDEF }
                || return $self->error_msg( bad_type => $name, 'undef' );
        }
        elsif ($args && ref $value eq CODE) {
            $self->debug("value is CODE with args, calling...") if DEBUG;

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
            $self->debug("value is a ", ref($value), " reference") if DEBUG;

            $ctor = $self->{ type }->{ ref $value } 
                 || $self->{ type }->{ OBJECT }
                 || return $self->error_msg( bad_type => $name, ref $value );
        }
        else {
            $self->debug("value is text") if DEBUG;
            
            $ctor = $self->{ type }->{ TEXT }
                 || return $self->error_msg( bad_type => $name, 'value' );
        }
    }

    return $ctor->($self, $name, $value, $parent, $args, @more);
}



sub no_var {
    my ($self, $name) = @_;
    return $self->use_var( $name => undef );
}


sub auto_var {
    my ($self, $handler) = @_;
    $self->{ auto_var } = $handler;
}


sub reset {
    my $self = shift;
    delete $self->{ vars };
}


sub with {
    my ($self, $params) = self_params(@_);
    my $data  = $self->{ data };
    my $class = ref $self || $self;
    bless {
        %$self,
# NOTE: we have two options here.  We can either pre-merge all the parent's
# data with the new params or we can leave it in the parent and rely on the
# child->parent lookup to find it later.  TODO: benchmark different approaches
#       data   => { %$data, %$params },
        data   => $params,
        vars   => { },
        parent => $self,
        lookup => $self,
    }, $class;
}


sub just {
    my ($self, $params) = self_params(@_);
    my $data  = $self->{ data };
    my $class = ref $self || $self;
    bless {
        %$self,
        data   => $params,
        vars   => { },
        parent => $self,
        lookup => undef,
    }, $class;
}


sub scope {
    my $self = shift;
    return $self->{ scope }
        || $self->error_msg( missing => 'scope' );
}
    
    

1;
