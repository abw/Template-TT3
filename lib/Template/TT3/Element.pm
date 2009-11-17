package Template::TT3::Element;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    utils     => 'self_params numlike refaddr',
    slots     => 'meta _next token pos',
    import    => 'class',
    constants => ':elem_slots :eval_args CODE ARRAY HASH BLANK',
    constant  => {   
        # define a new base_type for the T::Base type() method to strip off
        # when generate a short type name for each subclass op
        base_id       => 'Template::TT3::Element',
        is_whitespace => 0,
        is_delimiter  => 0,
        is_terminator => 0,
        eof           => 0,
    },
    alias => {
        delimiter  => \&null,
        terminator => \&null,
        as_dotop   => \&null,
        as_word    => \&null,
    };


our $MESSAGES = {
    no_rhs_expr     => "Missing expression after '%s'",
    no_rhs_expr_msg => "Missing expression after '%s' (%s)",
    no_dot_expr     => "Missing expression after dotop %s",
    missing_match   => "Missing '%s' to match '%s'",
    missing_for     => "Missing %s for '%s'.  Got '%s'",
    bad_assign      => "Invalid assignment to expression: %s",
    bad_method      => "The %s() method is not implemented by %s.",
    sign_bad_arg    => "Invalid argument in signature for %s function: %s",
    sign_dup_arg    => "Duplicate argument in signature for %s function: %s",
    sign_dup_sigil  => "Duplicate '%s' argument in signature for %s function: %s",
    undef_varname   => "Cannot use undefined value as a variable name: %s",
    undefined       => "Undefined value returned by expression: <1>",
    nan             => 'Non-numerical value "<2>" returned by expression: <1>',
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
# other generic parse methods
#-----------------------------------------------------------------------

sub accept {
    my ($self, $token) = @_;
    # accept the current token and advance to the next once
    $$token = $self->[NEXT];
    return $self;
}

sub reject {
    # return the $token passed to us
    $_[1];
}


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

sub next { 
    if (@_ == 1) {
        return $_[SELF]->[NEXT];
    }
    else {
        my ($self, $token) = @_;
        $$token = $self->[NEXT];
        return $$token;
    }
}


sub skip_delimiter { 
    # Most tokens aren't delimiters so they simply return the zeroth argument
    # ($self).  If a $token reference is passed as the first argument then we 
    # update it to reference the new token.  This advances the token pointer.
    my ($self, $token) = @_;
    $$token = $self if $token;
    return $self;
}

sub next_skip_ws {
    # delegate to the next token's skip_ws method
#    my ($self, $token) = @_;
#    $self->debug("next_skip_ws(), next is $self->[NEXT]  token is ", $token ? $$token : 'undefined');
    $_[0]->[NEXT] && $_[0]->[NEXT]->skip_ws($_[1]) 
}

sub as_postfix {
    # Most things aren't postfix operators.  The only things that are 
    # are () [] and { }.  So in most cases as_postfix() skips any whitespace
    # and delegates straight onto as_postop() on the next non-whitespace 
    # token.
    shift->skip_ws($_[1])->as_postop(@_);
}

sub as_postop {
    # args are: ($self, $lhs, $token, $scope, $prec)
    # default behaviour (for non-postop tokens) is to return $lhs without 
    # advancing $token
    return $_[1];
}

sub as_block {
    return shift->as_expr(@_);
}

sub as_exprs {
    my ($self, $token, $scope, $prec, $force) = @_;
    my (@exprs, $expr);

    #    $self->debug("as_exprs($self, $token, $scope, $prec)");
    #    $self->debug("as_exprs()  token is ", $$token->token);

    $token ||= do { my $this = $self; \$this };
 
    while ($expr = $$token->skip_delimiter($token)
                          ->as_expr($token, $scope, $prec)) {
        push(@exprs, $expr);

        if (DEBUG) {
            $self->debug("expr: $expr->[TOKEN] => $expr");
            $self->debug("token: $$token->[TOKEN]");
        }
    }

    return undef
        unless @exprs || $force;

    return $self->[META]->[ELEMS]->construct(
        block => $self->[TOKEN], $self->[POS], \@exprs
    );
}

sub as_filename {
    return BLANK;
}

sub as_args {
    return undef;
}

sub is {
    if (@_ == 3) {
        # if a $token reference is passed as the third argument then we 
        # advance it on a successful match
        my ($self, $match, $token) = @_;
        if ($self->[TOKEN] && $self->[TOKEN] eq $match) {
            $$token = $self->[NEXT];
            return $self;
        }
    }
    return $_[SELF]->[TOKEN] && $_[SELF]->[TOKEN] eq $_[1];
}

sub in {
    if (@_ == 3) {
        # as per in(), we advance the $token reference
        my ($self, $match, $token) = @_;
        my $result;
        if ($self->[TOKEN] && ($result = $match->{ $self->[TOKEN] })) {
            $$token = $self->[NEXT];
            return $result;
        }
    }
    $_[SELF]->[TOKEN] && $_[1]->{ $_[SELF]->[TOKEN] };
}

sub value {
    shift->not_implemented('in element base class');
}

sub variable {
    shift->not_implemented('in element base class');
}

sub values {
    $_[0]->debug("values() calling value()") if DEBUG;
    shift->value(@_);
}

sub list_values {
    $_[0]->debug("list_values() calling values()") if DEBUG;
    my $value = shift->value(@_);
    return ref $value eq ARRAY
        ? @$value
        : $value;
#    shift->values(@_);
}

sub pair {
    shift->not_implemented;
}

sub pairs {
    shift->not_implemented;
}

sub text {
    shift->value(@_);
}

sub number {
    my $self = shift;
    my $text = $self->value(@_);

    return 
        ! defined $text ? $self->error_undef
      : ! numlike $text ? $self->error_nan($text)
      : $text;
}


sub error_undef { 
    my $self = shift;
    $self->error_msg( undefined => $self->source, @_ );
}


sub error_nan { 
    my $self = shift;
    $self->error_msg( nan => $self->source, @_ );
}


sub missing {
    my ($self, $what, $token) = @_;
    return $self->error_msg( 
        missing_for => $what => $self->[TOKEN], $$token->[TOKEN]
    );
}

sub view {
    $_[CONTEXT]->view_element($_[SELF]);
}

sub view_guts {
    # used mostly for debugging - see T::TT3::View::Tokens::Debug
    self => refaddr $_[0],
    next => refaddr $_[0]->[NEXT],
    jump => refaddr $_[0]->[JUMP],
}

sub remaining_text {
    my $self = shift;
    my $elem = $self;
    my @text;
    while ($elem) {
        push(@text, $elem->[TOKEN]);
        $elem = $elem->[NEXT];
    }
    return @text
        ? join(BLANK, grep { defined } @text)
        : BLANK;
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

=head2 is($match,\$token)

This method can be used to test if if a token matches a particular value.
So instead of writing something like this:

    if ($token->token eq 'hello') {
        # ...
    }

You can write:

    if ($token->is('hello')) {
        # ...
    }

When you've matched successfully a token you usually want to do something
meaningful and move onto the next token.  For example:

    if ($token->is('hello')) {
        # do something meaningful
        print "Hello back to you!";

        # advance to the next token
        $token = $token->next;
    }
    else {
        die "Sorry, I don't understand '", $token->token, "\n";
    }

The C<is()> method accepts a reference to the current token as an optional
second argument. If the match is successful then the reference will be
advanced to point to the next token. Thus the above example can be written
more succinctly as:

    if ($token->is('hello', \$token)) {
        # do something meaningful
        print "Hello back to you!";
    }
    else {
        die "Sorry, I don't understand '", $token->token, "\n";
    }

=head2 in(\%matches,\$token)

This method is similar to L<in()> but allows you to specify a a reference to
a hash array of potential matches that you're interested in.  If the token
matches one of the keys in the hash array then the corresponding value will
be returned. 
    
    my $matches = {
        hello => 'Hello back to you',
        hey   => 'Hey, wazzup?',
        hi    => 'Hello',
        yo    => 'Yo Dawg',
    };

    if ($response = $token->in($matches)) {
        print $response;
    }
    else {
        die "Sorry, I don't understand '", $token->token, "\n";
    }

As with C<is()>, you can pass a reference to the current token as the 
optional second argument.  If the match is successful then the reference
will be advanced to point to the next token.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

