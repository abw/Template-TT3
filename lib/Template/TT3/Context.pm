package Template::TT3::Context;

use Template::TT3::Variables;
use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    import      => 'class',
    accessors   => 'variables scanner parent visiting',
    utils       => 'self_params',
    constants   => 'HASH CODE',
    constant    => {
        VARIABLES => 'Template::TT3::Variables',
        VISIT     => 'Template::TT3::Context::Visit',
    },
    alias       => {
        get     => \&get_var,
        set     => \&set_var,
    },
    messages    => {
        bad_type    => 'Invalid variable type for %s: %s',
        missing     => '%s not found in context',
    };


sub init {
    my ($self, $config) = @_;

    $self->init_hub($config);

    my $vars = $self->VARIABLES->new($config);

#    $self->{ VARS  } = $vars;
    # TODO: merge in these last few methods or otherwise jiggle them about
    $self->{ types } = $vars->types;
    $self->{ type  } = $vars->constructors;
    $self->{ data  } = $config->{ data } || { };
    
    $self->debug("context init: ", $self->dump_data($self)) if DEBUG;
    
#    $self->{ variables } = $self->VARIABLES->new( 
#        data => $config->{ variables },
#    );
    
    $self->{ templates } = $config->{ templates };
    $self->{ scanner   } = $config->{ scanner };
    $self->{ scope     } = $config->{ scope };
    $self->{ visiting  } = [ ];
    
    return $self;
}


sub child {
    my ($self, $params) = self_params(@_);
    my $class = ref $self || $self;
    bless {
        %$self,
        %$params,
    }, $class;
}


#-----------------------------------------------------------------------
# variables
#-----------------------------------------------------------------------

sub var {
    my $self = shift;
    
    return @_ > 1
        ? $self->set_var(@_)
        : $self->get_var(@_);
}


sub get_var {
    my ($self, $name, $context) = @_;
    my ($var, $value);

    # If we need to lookup a variable in a parent context then we pass the
    # child context as an argument so that the parent creates a new variable
    # bound to the child context, not the parent.  Otherwise we use $self.
    $context ||= $self;

    $self->debug("$self get_var($name) in $context") if DEBUG ;

    if ($var = $self->{ vars }->{ $name }) {
        # FIXME: had to add this to fix the gnarly old goat bug that prevented
        # expressions in a child context from seeing new variables created
        # in a parent context
        $self->debug("found $name in vars cache: $var") 
            if DEBUG;

        # If we're returning a cache variable to a context that isn't our
        # own (typically a child context in a 'with' or 'just' block) then 
        # we need to graft a clone of the variable onto the new context.
        return ($self == $context)
            ? $var
            : $var->graft($context);
    }
    elsif (exists $self->{ data }->{ $name }) {
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
        $self->debug("asking lookup ($self->{ lookup }) for $name") if DEBUG;
        return $self->{ lookup }->get_var($name, $context);
    }
    else {
        $self->debug("$self $name is missing") if DEBUG;
        return $self->no_var($name);
    }
}


sub set_var {
    my ($self, $name, $value) = @_;

    $self->debug("$self set_var($name, $value)") if DEBUG;
    
    # we don't update the target data, just the local variable wrapper
    return $self->{ vars }->{ $name } 
         = $self->use_var( $name => $value );
}


sub set_vars {
    my ($self, $params) = self_params(@_);
    my $vars = $self->{ vars };
    
    while (my ($name, $value) = each %$params) {
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
    return $self;
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


#-----------------------------------------------------------------------
# For commands/controls like TAGS, COMMANDS, etc., we want to be able
# to evaluate a set of arguments like this: [? COMMANDS include ?] or 
# this: [? COMMANDS { wrap = wrapper, inc = include }.  We want the 
# values ('wrapper' and 'include') to evaluate right back to their 
# literal names so that we end up with a hash that we can pass to the
# relevant internal method, e.g. { wrap => 'wrapper', inc => 'include' }.
# To achieve this we create a new detached (just) context with an 
# auto_var handler that simply returns the variable name
#-----------------------------------------------------------------------

sub loopback {
    $_[0]->debug("installing loopback") if DEBUG;
    shift->just->auto_var( \&loopback_var );
}

sub loopback_var {
    $_[0]->debug("loopback: $_[1]") if DEBUG;
    return $_[1];
}    


#-----------------------------------------------------------------------
# templates
#-----------------------------------------------------------------------

sub fill {
    my $self     = shift;
    my $template = $self->any_template(shift);
    return $template->fill(@_);
}


sub template {
    shift->templates->template(@_);
}


sub any_template {
    my $self      = shift;
    my $templates = $self->templates;
    return $templates->template(@_)
        || $self->error( $templates->reason );
}


sub templates {
    my $self = shift;
    return $self->{ templates } 
        ||= $self->lookup('templates');
}


sub lookup {
    my $self   = shift;
    my $lookup = $self->{ lookup };
    
    # act as a simple accessor when called without arguments
    return $lookup unless @_;
 
    # otherwise lookup the named item
    my $item = shift;

    $self->debug("looking up $item") if DEBUG;
 
    # walkup through the parent chain looking for the item
    while ($lookup) {
        $lookup->{ $item } && return;
        $lookup = $lookup->{ lookup };      # FIXME: or parent?
    }
    
    $self->debug("asking hub for $item") if DEBUG;
    
    # failing that ask the hub to provide it
    return $self->hub->$item;
}
    

sub scope {
    my $self = shift;
    return $self->{ scope }
        || $self->error_msg( missing => 'scope' );
}
 

sub dump_up {
    my $self  = shift;
    my $n     = shift || 0;
    my $vars  = $self->dump_data_depth($self->{ vars }, 1);
    my $data  = $self->dump_data_depth($self->{ data }, 1);
    for ($vars, $data) {
        s/\n/\n    /g;
    }
    return "$n $self {\n    vars => $vars\n    data => $data\n}\n"
        . ($self->{ parent } ? $self->{ parent }->dump_up($n+1) : '');
}


#-----------------------------------------------------------------------
# visit($visitor, @args)
#
# The visit() method creates a Template::TT3::Context::Visit object 
# as a blessed ARRAY containing the $context, $visitor and any optional
# @args.  Any methods called against the visit object are delegated onto
# the $visitor object.  The $context and any additional @args are passed
# to the method along with any other arguments specified when the method
# was called against the visit object.  In the usual case, a $visitor is
# a template object.
#
#  e.g.  $context->visit($object, 10)->some_method(20)
# calls  $object->some_method($context, 10, 20) 
#
# In addition, the visit object calls $context->enter($visitor) before
# calling the delegate method.  This adds the $visitor to the 'visiting' 
# list in the context (effectively the template caller stack).  To avoid
# stack corruption, the delegate method call is wrapped in an eval 
# block.  When then method call is complete, the visitor object is 
# removed from the visiting stack by a call to $context->leave.  If an 
# error occurred it is then re-thrown.  Otherwise the return value (or 
# values if called in list context) is returned.
#-----------------------------------------------------------------------

sub visit {
    bless [@_], VISIT;
}

sub enter {
    $_[0]->debug("entering ", $_[1]) if DEBUG;
    push( @{ $_[0]->{ visiting } }, $_[1] );
}

sub leave {
    $_[0]->debug("leaving ", $_[0]->{ visiting }->[-1]) if DEBUG;
    pop( @{ $_[0]->{ visiting } } );
}


package Template::TT3::Context::Visit;
our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my ($method) = ($AUTOLOAD =~ /([^:]+)$/ );
    return if $method eq 'DESTROY';
    
    # unpack arguments passed to the visit() method: context, visitor, args
    my ($context, $visitor, @args) = @$self;
    $context->enter($visitor);

    # call method on visitor object in eval block, and downgrade
    if (wantarray) {
        my @result = eval { $visitor->$method($context, @args, @_) };
        # TODO: should we call error() against visitor or context?
        $context->leave;
        $visitor->error($@) if $@;
        return @result;
    }
    else {
        my $result = eval { $visitor->$method($context, @args, @_) };
        $context->leave;
        $visitor->error($@) if $@;
        return $result;
    }
}



1;
