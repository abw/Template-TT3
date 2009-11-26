package Template::TT3::Variable;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    # Slot methods are read/write, but we want to make value() read only.  
    # So we use val() for the generated slot method and define value() below
    slots     => 'meta name_slot val parent args',
    utils     => 'self_params weaken',
    constants => ':type_slots BLANK',
    constant  => {
        VARIABLES => 'Template::TT3::Variables',
    },
    alias     => {
        list      => \&get,
        value     => \&get,
        values    => \&get,
#       pairs     => \&get,
        maybe     => \&get,
    },
    messages  => {
        undefined  => '"%s" is undefined',
        no_vmethod => '"<2>" is not a valid <1> method in "<3>.<2>"', 
        bad_pairs  => 'Cannot make pairs from variable expression: %s',
    };
        

#-----------------------------------------------------------------------
# constructor methods
#-----------------------------------------------------------------------

sub new {
    my $class = shift;
    bless [@_], $class;
}


sub graft {
    my ($self, $context) = @_;
    my $clone = [@$self];
    $clone->[CONTEXT] = $context;
    bless $clone, ref $self || $self;
}


sub constructor {
    my ($self, $params) = self_params(@_);
    my $class   = ref $self || $self;
    my $config  = $self->configuration($params);
#    my $vars    = $config->{ variables } 
#               || class( $self->VARIABLES )->load->name->prototype;
    my $vars = 'TODO: VARS SLOT IS DEPRECATED';
    
    # TODO: shouldn't we be asking the types for our vmethods?
    my $methods = $self->class->hash_vars( METHODS => $config->{ methods } );
    my $meta    = [$config, $vars, $methods];
    
    return sub {
        $self->debug("args: ", $self->dump_data(\@_)) if DEBUG;
        my $var = bless [$meta, @_], $class;
        weaken $var->[CONTEXT];
        return $var;
    };
}


sub configuration {
    $_[1];
}



#-----------------------------------------------------------------------
# basic get/set methods for a variable.
#-----------------------------------------------------------------------


sub get {
    return $_[0]->[VALUE];
}


sub set {
    my ($self, $value) = @_;
#    $self->debug("setting variable $self->[NAME] to $value");
    return $self->[CONTEXT]->set_var( 
        $self->[NAME],
        $value,
    );
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
# TODO: Look for element.  Does this branch ever get called or does 
# Undef take care of it?
#        my $element = shift;
        
        return $self->error_msg( undefined => "var:" . $self->fullname );
    }
}


sub pairs {
    my ($self, $element) = @_;
    $self->debug("variable pairs not allowed");
    return $element
        ? $element->fail_pairs_bad
        : $self->error_msg( bad_pairs => $self->fullname );
}


sub ref {
    CORE::ref $_[0]->[VALUE];
}


sub dot {
    shift->not_implemented;
}


sub apply {
    # function application has no effect on things that aren't CODE refs
    # so we define a default method in the base class that returns $self
    # and allow Template::TT3::Variable::Code to redefine it.
    $_[0];
}


sub TMP_expand {
    shift->not_implemented;
}


sub name {
    CORE::ref $_[0]->[NAME]
        ? $_[0]->[NAME]->source
        : $_[0]->[NAME];
}


sub names {
    my $self  = shift;
    my @names = $self->[PARENT]
        ? ($self->[PARENT]->names, $self->name)
        : ($self->name);

    return wantarray
        ?  @names
        : \@names;
}


sub fullname {
    join('.', shift->names);
}


sub variables {
    shift->[CONTEXT];
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


sub hush {
    # hush, hush, thought I heard her calling my name...
    return BLANK;
}

1;

__END__

=head1 NAME

Template::TT3::Variable - base class for template variable objects

=head1 DESCRIPTION

The C<Template::TT3::Variable> module defines a base class for objects used
to represent variables in TT3.  A variable is a very small, lightweight
object that encapsulates the name of a variable and its value, along with
some other housekeeping metadata.

Variables are typed. For example, variables that have hash references as
values are represented by L<Template::TT3::Variable::Hash> variable objects,
those that are list references are represented by
L<Template::TT3::Variable::List> objects, and so on.

The L<Template::TT3::Variables> factory module can be used to create 
variable objects.

    use Template::TT3::Variables;
    
    my $vars = Template::TT3::Variables->new;
    
    my $hash = $vars->var( 
        user => { 
            name  => 'Ford Prefect',
            email => 'ford@heart-of-gold.com',
        }
    );

These objects collectively implement the runtime functionality of variables
in TT3.  The L<get()> method can be called to fetch the current value of the
variable.

    my $user = $hash->get;
    print $user->{ name };      # Ford Prefect

The L<set()> method can be used to set a new variable value.  However, it is 
a non-destructive action that doesn't modify the variable object or the 
original data.  Instead it returns a I<new> variable reference containing 
the new value.  It is effectively syntactic sugar for creating a new variable
with the same name as an existing one.

    my $old = $vars->var( user => 'Arthur Dent' );
    my $new = $old->set('Ford Prefect');
    
    print $old->value;          # Arthur Dent
    print $new->value;          # Ford Prefect
    
The L<dot()> method can be called to perform dot operations on the hash.  
This includes accessing hash items and calling virtual methods.

    my $name = $hash->dot('name');
    my $keys = $hash->dot('keys');

The L<dot()> method returns a new L<Template::TT3::Variable> object to 
represent the result.  Thus, a fragment of template code like this:

    [% user.name.length %]

Can be implemented in Perl like this:

    $vars->var('user')->dot('name')->dot('length')->get;

Note that we must call the L<get()> value right at the end to return the final
variable value. Rather surprisingly, this gives slightly better performance
than the current TT2 implementation for accessing variables, despite the fact
that there's rather a lot of wrapping and delegating going on.

=head1 METHODS

=head2 new()

This defines a default constructor method for creating variable objects.
It exists for the sake of completeness but most if not all of the internal
TT code uses the L<constructor()> method to return a constructor function
that can then be called independently.

=head2 graft($context)

Clones a variable and grafts it onto a new context.  This is used when a 
child context (e.g. in a C<with> or C<just> block) accesses a variable
defined in a parent context (i.e. the outer block).  We can't re-use the 
cached variable (shame) because it's bound to the outer context.  If we
did re-use it then any subsequent updates to that variable (e.g. L<set()>) 
in the inner context would affect the C<vars> cache in the outer context.
That would be bad.

So instead we clone the variable and update the C<CONTEXT> slot to point
to the new inner context.

=head2 constructor()

This method returns a constructor function for variable instances.

    # fetch a constructor function for hash variables
    my $HashVar = Template::TT3::Variable::Hash->constructor;
    
    # call it to create a variable instance
    my $hashvar = $HashVar->( 
        user => { 
            name => 'Ford Prefect' 
        } 
    )

=head2 configuration(\%config)

This method stub is provided for subclasses to examine or modify the
configuration parameters that are bound inside the closure returned by the
L<constructor()> method. In the base class this method simply returns
unmodified the hash reference passed to it as an argument by the
L<constructor()> method.

=head1 get()

Returns the current value of the variable.

    my $var = $vars->var( user => 'Slartibartfast' );
    
    print $var->value;          # Slartibartfast

=head1 set($value)

Used to set a new variable value.  Note that this is a non-destructive 
action that returns a I<new> variable reference containing the new value.

    # create a variable called 'user' than contains a hash reference
    my $old = $vars->use_var( user => { ... } );
    
    # $old is now a Template::TT3::Variable::Hash object
    
    # create a new value for the variable
    my $new = $old->set('Ford Prefect');
    
    # $new is now a Template::TT3::Variable::Text object, $old is unchanged

