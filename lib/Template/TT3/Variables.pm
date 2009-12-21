package Template::TT3::Variables;

use Template::TT3::Class::Factory
    version     => 2.69,
    debug       => 0,
    item        => 'variable',
    path        => 'Template(X)::(TT3::|)Variable',
    utils       => 'params',
    import      => 'CLASS',
    constants   => 'HASH',
    names       => {                    # NOTE: this defines $VARIABLE_NAMES
        # There are the types returned by Perl's ref()
        SCALAR  => 'code',
        ARRAY   => 'list',
        HASH    => 'hash',
        CODE    => 'code',
#       GLOB    => 'glob',

        # These are the internal names we use for everything else
        map { $_ => $_ }
        qw( text list hash code object undef missing )
#       PARAMS  => 'params',
    },
    messages => {
        bad_type => 'Invalid type specification for %s: %s',
    };


sub preload {
    my $self   = shift->prototype;
    my $types  = $VARIABLE_NAMES;       # Defined by 'names' hook above
    my $loads  = { };

    $self->debug("preload() types: ", $self->dump_data($types)) if DEBUG;
    
    foreach my $type (keys %$types) {
        $loads->{ $type } = $self->variable($type);
        $self->debug("preload $type => ", $loads->{ $type }) if DEBUG;
    }
    
    return $loads;
}


sub constructors {
    my $self    = shift->prototype;
    my $builtin = $self->preload;            # TODO: other types too
    my $userdef = params(@_);
    my $types   = $self->hub->types;

    $self->debug(
        "constructors() types:\nBUILTIN:", 
        $self->dump_data($builtin), "\n",
        "USERDEF: ", $self->dump_data($userdef)
    ) if DEBUG;
    
    my $input = { 
        # we're not interested in the class names that are in the $builtin
        # values, we just want a mapping from key to key, e.g. undef => undef
        (   
            map { $_ => $_ }
            keys %$builtin
        ),
        # then we allow the user-defined types to over-ride them and/or add 
        # to them, e.g. undef => blank, My::Class => { ... }, etc.
        %$userdef 
    };
    
    $self->debug(
        "combined:", 
        $self->dump_data($input), "\n",
    ) if DEBUG;
    
    my $output = { };
    
    foreach (keys %$input) {
        my $key = $_;
        my $cfg = $input->{ $key }; 
        my ($type, $vtable, $utable, $methods);

        # TODO: allow methods to be set to 0: text => { methods => 0 }
        # or as a short-cut, text => 0.  I don't think we can allow any 
        # false value to skip the type altogether as that would allow the 
        # user to disable the text, hash, list or other inbuilt types which
        # would probably cause TT to fail.

        if (! $cfg) {
            $type = $builtin->{ $key } && $key      # a builtin type
                 || 'object';                       # or an object type
            $methods = { };
        }
        elsif (ref $cfg eq HASH) {
            $type = $cfg->{ type }                  # declared type
                 || $builtin->{ $key } && $key      # or a builtin type
                 || 'object';                       # or an object type
        }
        elsif (ref $cfg) {
            return $self->error_msg( bad_type => $key, $cfg );
        }
        else {
            $type = $cfg;
            $cfg = { };
        }

        unless ($methods) {
            # merge inbuilt virtual methods with any user-supplied ones
            $vtable = $types->try->vtable($type) || { };
            $utable = $cfg->{ methods } || $cfg;
            $methods = { %$vtable, %$utable };
        }

        $output->{ $key } = $self->variable($type)->constructor( 
            methods => $methods
        );
        
        $self->debug(
            "$key => $type => ", 
            $self->dump_data($methods)
        ) if DEBUG
    }

    return $output;
}


sub found {
    my ($self, $type, $module) = @_;
    return $module;
}


1;

__END__
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

sub types {
    shift->prototype->{ types };
}

sub constructors {
    shift->prototype->{ type };
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

