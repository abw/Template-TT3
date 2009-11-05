die "Template::TT3::Ops is deprecated.... use Template::TT3::Elements instead";

#========================================================================
#
# Template::TT3::Ops
#
# DESCRIPTION
#   A collection of the various classes implemented to represent 
#   primitive operations that can be perfomed in a template.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Ops;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base Badger::Prototype',
    import    => 'class',
    utils     => 'params',
    constants => 'HASH',
#    accessors => 'ops constructors',
    messages  => {
        no_module => 'No module defined for opcode: %s',
    };

our $OPS = {
    text        => 'Template::TT3::Op::Text',
    whitespace  => 'Template::TT3::Op::Whitespace',
    tag_start   => 'Template::TT3::Op::TagStart',
    tag_end     => 'Template::TT3::Op::TagEnd',
    number      => 'Template::TT3::Op::Number',
    add         => 'Template::TT3::Op::Add',
    subtract    => 'Template::TT3::Op::Subtract',
    word        => 'Template::TT3::Op::Word',
    keyword     => 'Template::TT3::Op::Keyword',
    var_node    => 'Template::TT3::Op::VarNode',
    variable    => 'Template::TT3::Op::Variable',
    dot         => 'Template::TT3::Op::Dot',
};


sub init {
    my ($self, $config) = @_;
    $self->{ ops } = $self->class->hash_vars( OPS => $config->{ ops } );
    $self->init_constructors($config);
    return $self;
};

sub init_constructors {
    my $self   = shift->prototype;
    my $params = params(@_);
    my $ops    = $self->ops;
    
    $self->{ constructors } = {
        map {
            # load each module and call the constructor() method to generate
            # a constructor closure which we can call as a subroutine and 
            # binds all the right data in place.
            my $name   = $_;
            my $module = $ops->{ $name };
            my $config;

            $self->debug("generating constructor for $_ => $module") if DEBUG;
            
            if (ref $module eq HASH) {
                $config = { 
                    ops => $self,
                    %$params, 
                    %$module,
                };
                $module = $config->{ module }
                    || return $self->error_msg( no_module => $_ );
            }
            else {
                $config = { 
                    ops => $self,
                    %$params,
                };
            }
        
            $name => class($module)->load->name->constructor($config);
        }
        keys %$ops
    };
}


sub ops {
    shift->prototype->{ ops };
}

sub constructors {
    shift->prototype->{ constructors };
}

sub op {
    my $self = shift;
    my $type = shift;
    my $code = $self->{ constructors }->{ $type }
        || return $self->error_msg( invalid => op => $type );
    return $code->(@_);
}


1;
