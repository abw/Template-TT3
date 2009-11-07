package Template::TT3::Element;

use Template::TT3::Class
    base      => 'Template::TT3::Base',
    version   => 3.00,
    utils     => 'self_params',
    slots     => 'meta next token pos',
    import    => 'class',
    constants => ':elem_slots CODE ARRAY HASH',
    constant  => {   
        # define a new base_type for the T::Base type() method to strip off
        # when generate a short type name for each subclass op
        base_id       => 'Template::TT3::Element',
        is_whitespace => 0,
        is_terminator => 0,
        eof           => 0,
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
    undefined       => "Undefined value returned by expression: <1>",
    nan             => 'Non-numerical value "<2>" returned by expression: <1>',
    missing_after   => 'Missing %s after %s: %s',
};


#class->alias(
#    as_postop => 'self',
#);


sub new {
    my ($class, @self) = @_;
    bless \@self, $class;
}


sub init_meta {
    my ($self, $params) = self_params(@_);
    return [$params, @$params{ qw( elements lprec rprec ) }];
}


sub constructor {
    my ($self, $params) = self_params(@_);
    my $class = ref $self || $self;
    my $meta  = $self->init_meta($params);
    return sub {
        bless [$meta, undef, @_], $class;
    };
}


sub configuration {
    # hook for subclasses
    return $_[1];
}


sub become {
    my ($self, $type) = @_;
    my $class = $self->[META]->[ELEMS]->element_class($type)
        || return $self->error_msg( invalid => element => $type );
    bless $self, $class;
}



#-----------------------------------------------------------------------
# metadata methods
#-----------------------------------------------------------------------

sub lprec { $_[0]->[META]->[LPREC]  }
sub rprec { $_[0]->[META]->[RPREC]  }


#-----------------------------------------------------------------------
# nullop methods to use for aliases
#-----------------------------------------------------------------------

sub self { $_[0] }
sub null { undef }


#-----------------------------------------------------------------------
# whitespace handling methods
# NOTE: we should be able to remove the $_[0]->[NEXT] check now that 
# we have an explicit EOF token (which must handle this)
#-----------------------------------------------------------------------

sub skip_ws { 
    # Most tokens aren't whitespace so they simply return the zeroth argument
    # ($self).  If a $token reference is passed as the first argument then we 
    # update it to reference the new token.  This advances the token pointer.
    my ($self, $token) = @_;
    $$token = $self if $token;
    return $self;

# NOTE: I'm wary of this because I've had aliasing problems...
#    $self->debug("skip_ws(), next is $self->[NEXT]  token is ", $token ? $$token : 'undefined');
#    ${$_[1]} = $_[0] if $_[1]; 
#    $self->debug("set next to ", $token ? $$token : 'undefined', "  returning $_[0]");
#    $_[0];
}

sub next_skip_ws {
    # delegate to the next token's skip_ws method
#    my ($self, $token) = @_;
#    $self->debug("next_skip_ws(), next is $self->[NEXT]  token is ", $token ? $$token : 'undefined');
    $_[0]->[NEXT] && $_[0]->[NEXT]->skip_ws($_[1]) 
}


sub as_postop {
    # args are: ($self, $lhs, $token, $scope, $prec)
    # default behaviour (for non-postop tokens) is to return $lhs without 
    # advancing $token
    return $_[1];
}

sub as_block {
    return shift->as_expr(@_);
    
#    my ($self, $token, $scope, $prec) = @_;
#    my (@exprs, $expr);
#    
#    while ($expr = $$token->as_expr($token, $scope, $prec)) {
#        push(@exprs, $expr);
#    }
#    
#    return $self->[META]->[ELEMS]->construct(
#        block => $self->[TOKEN], $self->[POS], \@exprs
#    )
#    if @exprs;
}
    

sub is {
    $_[0]->[TOKEN] && $_[0]->[TOKEN] eq $_[1];
}


sub error_undef { 
    my $self = shift;
    $self->error_msg( undefined => $self->source, @_ );
}

sub error_nan { 
    my $self = shift;
    $self->error_msg( nan => $self->source, @_ );
}

    
1;

__END__

# default methods to access other items in a token instance or generate
# view of it
sub self    { $_[0] }
sub source  { $_[0]->[TOKEN] }
sub sexpr   { '<' . $_[0]->type . ':' . $_[0]->text . '>' }


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

=head1 DESCRIPTION

Base class for objects which represent nodes in the opcode tree 
generated to represent a parsed template.

=head1 METHODS

=head2 new()

Simple constructor blesses all arguments into list based object.

=head2 constructor() 

Returns a constructor function.

=head2 configuration($config) 

Stub configuration method for subclasses to redefine if they need to

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

