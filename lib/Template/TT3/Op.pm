#========================================================================
#
# Template::TT3::Op
#
# DESCRIPTION
#   Base class for objects which represent nodes in the opcode tree 
#   generated to represent a parsed template.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Op;

use Template::TT3::Class
    base      => 'Template::TT3::Base',
    version   => 3.00,
    utils     => 'self_params',
    slots     => 'meta text from to',
    constants => ':op_slots CODE ARRAY HASH',
    constant  => {   
        # define a new base_type for the T::Base type() method to strip off
        # when generate a short type name for each subclass op
        base_id  => 'Template::TT3::Op',
    };

our $MESSAGES = {
    no_rhs_expr     => "Missing expression after '%s'",
    no_rhs_expr_msg => "Missing expression after '%s' (%s)",
    no_dot_expr     => "Missing expression after dotop %s",
    missing_match   => "Missing '%s' to match '%s'",
    bad_assign      => "Invalid assignment to expression: %s",
    bad_method      => "The %s() method is not implemented by %s.",
    sign_bad_arg    => "Invalid argument in signature for %s function: %s",
    sign_dup_arg    => "Duplicate argument in signature for %s function: %s",
    sign_dup_sigil  => "Duplicate '%s' argument in signature for %s function: %s",
    undef_varname   => "Cannot use undefined value as a variable name: %s",
};


# simple constructor blesses all arguments into list based object
sub new {
    my ($class, @self) = @_;
    bless \@self, $class;
}


# constructor() method returns a constructor closure to bind state
sub constructor {
    my ($self, $params) = self_params(@_);
    my $class   = ref $self || $self;
    my $config  = $self->configuration($params);
    my $ops     = $config->{ ops };
    my $meta    = [$config, $ops];  # more to add
    return sub {
        bless [$meta, @_], $class;
    };
}


# configuration() is a stub for subclasses to redefine if they need to
sub configuration {
    return $_[1];
}


# define shortcut methods to access metdata items
sub precedence    { $_[0]->[META]->[PREC]  }
sub associativity { $_[0]->[META]->[ASSOC] }
sub binds_left    { $_[0]->[META]->[ASSOC] == LEFT  }
sub binds_right   { $_[0]->[META]->[ASSOC] == RIGHT }

# default methods to access other items in a token instance or generate
# view of it
sub self   { $_[0] }
sub source { $_[0]->[TEXT] }
sub sexpr  { '<' . $_[0]->type . ':' . $_[0]->text . '>' }

# default behaviour for evaluating an op in list context is to return 
# whatever it returns in scalar context
sub values {
#    $_[0]->debug("called: " . join(', ', (caller())[0..2]));
    shift->value(@_);
}

# default behaviour for evaluating an op in scalar context in undefined
sub value {
    shift->not_implemented(" for $_[0] at " . join(', ', (caller())[0..2]));
}

# collapse a list of items down to a single string
sub collapse {
    my $self = shift;
    return join('', map { ref $_ ? expand($self, $_) : $_ } @_);
}

# expand references into their constituent parts
sub expand {
    my ($self, $item) = @_;
    my $ref = ref $item || return $item;
    my $m;
        
    if ($ref eq CODE) {
        warn "WARNING! making delayed call to code during final expansion\n";
        return ($item = $item->());   # force scalar context
    }
    elsif ($ref eq ARRAY) {
        return collapse($self, @$item);
    }
    elsif ($ref eq HASH) {
        return collapse($self, %$item);
    }
    elsif (blessed $item && ($m = $item->can('tt_expand'))) {
        return $m->($item);
    }
    else {
        return $self->error("Cannot expand $ref reference\n");
    }
}

# some custom methods, effectively roles, that various op subclasses may
# implement to do something meaningful

sub assignment_methods {
    shift->not_implemented;
#    $_[0]->error_msg( bad_assign => $_[0]->source );
}

sub signature {
    shift->bad_signature('bad_arg');
}

sub bad_signature {
    my $self = shift;
    my $type = shift;
    my $name = shift;
    $name = $name ? "$name()" : 'anonymous';
    $self->error_msg( "sign_$type" => $name, $self->source );
}

# methods to return the leftmost and rightmost leaf node of a subtree
*left_edge  = \&self;
*right_edge = \&self;


1;

__END__
