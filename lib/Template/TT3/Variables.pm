package Template::TT3::Variables;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    import    => 'class',
    base      => 'Template::TT3::Base Badger::Prototype',
    utils     => 'self_params',
    constants => 'HASH CODE',
    messages  => {
        bad_type  => 'Invalid variable type for %s: %s',
        no_module => 'No module defined for variable type: %s',
    },
    constant  => {
        TYPES => 'Template::TT3::Types',
    },
    alias     => {
        init  => \&init_variables,
    };

use Template::TT3::Types;
our $TYPES = {
    UNDEF  => 'Template::TT3::Variable::Undef',
    TEXT   => 'Template::TT3::Variable::Text',
    HASH   => 'Template::TT3::Variable::Hash',
    ARRAY  => 'Template::TT3::Variable::List',
    CODE   => 'Template::TT3::Variable::Code',
    OBJECT => 'Template::TT3::Variable::Object',
#    'Template::TT3::Type::Params' => 'Template::TT3::Variable::Hash',
};


sub init_variables {
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
#               variables => $self,
                methods   => $vmethods->{ $_ },
                %$config,
            );
        } 
        keys %$types
    };

    $self->{ types } = $types;
    $self->{ type  } = $ctors;
    
#    $self->{ data  } = $config->{ data } || { };
#    $self->{ vars  } = { };
    return $self;
}


sub variable {
    my ($self, $name, $value, $parent, $args, @more) = @_;
    my $ctor;

    TYPE_SWITCH: {
        $self->debug("var($name, $value)\n") if DEBUG;
        
        if (! defined $value) {
            $ctor = $self->{ type }->{ UNDEF }
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
            $ctor = $self->{ type }->{ ref $value } 
                 || $self->{ type }->{ OBJECT }
                 || return $self->error_msg( bad_type => $name, ref $value );
        }
        else {
            $ctor = $self->{ type }->{ TEXT }
                 || return $self->error_msg( bad_type => $name, 'value' );
        }
    }

    return $ctor->($name, $value, $parent, $args, @more);
}


sub types {
    shift->prototype->{ types };
}

sub constructors {
    shift->prototype->{ type };
}


# tmp hack to try out automatically resolved data

sub auto {
    my ($self, $handler) = @_;
    $self->{ auto } = $handler;
}

    
1;


=head1 NAME

Template::TT3::Variables - factory for template variable objects

=head1 NOTE

The functionality for this module has been (mostly) moved into 
L<Template::TT3::Context>.  Once the final few bits have been merged
this module will be deprecated.

I<OR> this will become the variable managing base class for 
L<Template::TT3::Context>.  I haven't quite decided yet.

=head1 DESCRIPTION

The C<Template::TT3::Variables> module defines a factory for creating 
template variable objects.  Variable objects are subclasses of 
L<Template::TT3::Variable> which acts as small, lightweight wrappers
around data values.  They implement the additional behaviours that make
TT variables different from basic Perl variables.

For example, the following template fragment:

    [% user.name.length %]

Can be implemented in Perl like so:

    $vars->dot('user')->dot('name')->dot('length')->get;

Here C<$root> is a C<Template::TT3::Variables> object.

