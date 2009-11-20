package Template::TT3::Element;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    utils     => 'self_params numlike refaddr is_object',
    slots     => 'meta _next token pos',
    import    => 'class CLASS',
    constants => ':elements CODE ARRAY HASH BLANK CMD_PRECEDENCE FORCE',
    constant  => {   
        # define a new base_type for the T::Base type() method to strip off
        # when generate a short type name for each subclass op
        base_id         => 'Template::TT3::Element',
#        is_whitespace   => 0,
#        is_delimiter    => 0,
#        is_terminator   => 0,
        eof             => 0,
        # default names for parser arguments - see T::TT3::Element::Role::*Expr
        ARG_NAME        => 'name',
        ARG_EXPR        => 'expression',
        ARG_BLOCK       => 'block',
        EOF             => 'end of file',
    },
    alias => {
        delimiter       => \&null,
        terminator      => \&null,
        as_expr         => \&null,
        as_dotop        => \&null,
        as_word         => \&null,
        as_args         => \&null,
        as_signature    => \&null,
        as_filename     => \&null,
    };


our $MESSAGES = {
    no_rhs_expr     => "Missing expression after '%s'",
    no_rhs_expr_msg => "Missing expression after '%s' (%s)",
    no_dot_expr     => "Missing expression after dotop %s",
    missing_match   => "Missing '%s' to match '%s'",
    missing_for     => "Missing %s for '%s'.  Got '%s'",
    missing_for_eof => "Missing %s for '%s'.  End of file reached.",
    bad_assign      => "Invalid assignment to expression: %s",
    bad_method      => "The %s() method is not implemented by %s.",
    sign_bad_arg    => "Invalid argument in signature for %s: %s",
    sign_dup_arg    => "Duplicate argument in signature for %s: %s",
    sign_dup_sigil  => "Duplicate '<4>' argument in signature for %s: %s",
    undef_varname   => "Cannot use undefined value as a variable name: %s",
    undefined       => "Undefined value returned by expression: <1>",
    undefined_in    => "Undefined value returned by '<2>' expression: <1>",
    nan             => 'Non-numerical value "<2>" returned by expression: <1>',
    not_follow      => "'%s' cannot follow '%s'",
    odd_pairs       => 'Cannot make pairs from an odd number of items (%s): %s',
};



#-----------------------------------------------------------------------
# constructor / initialisation methods
#-----------------------------------------------------------------------

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


sub branch {
    # return existing branch when called without args
    return $_[SELF]->[BRANCH]
        if @_ == 1;

    my $self = shift;
    my $tail = $self;
    my $element;
    
    if (@_ == 1 && is_object(CLASS, $_[1])) {
        $element = shift;
        $self->debug("adding passed element to branch: $element") if DEBUG;
    }
    else {
        $element = $self->[META]->[ELEMS]->construct(@_);
    }
        
    # chase down the last node in any existing branch
    while ($tail->[BRANCH]) {
        $tail = $tail->[BRANCH];
    }
    
    $tail->[BRANCH] = $element;
    
    return $element;
}


# Hmm... this is clumsy... we're already using next() to fetch the current
# NEXT token and we can't overload it to accept an argument to set a new
# NEXT (to make it work the same way as branch()) because it already accepts
# an argument (a token ref, to advance the pointer).  Until I've had a 
# chance to rethink the names I'm just going to call it then().

sub then {
    my $self = shift;
    my $element;
    
    if (@_ == 1 && is_object(CLASS, $_[1])) {
        $element = shift;
        $self->debug("adding passed element to branch: $element") if DEBUG;
    }
    else {
        $element = $self->[META]->[ELEMS]->construct(@_);
    }
        
    $self->[NEXT] = $element;
    
    return $element;
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
# generic parse methods
#-----------------------------------------------------------------------

sub accept {
    my ($self, $token) = @_;

    # accept the current token and advance to the next one
    $$token = $self->[NEXT];
    
    return $self;
}


sub accept_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # accept the current token and advance to the next one
    $$token = $self->[NEXT];

    return $self;
}


sub reject {
    # return the $token passed to us
    $_[1];
}


sub is {
    # Check to see if the token matches that specifed: 
    # e.g. if ($token->is('foo'))
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
    # See if the token is in the hash ref passed: 
    # e.g. if ($token->in({ foo => 1, bar => 2 }))
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


#-----------------------------------------------------------------------
# whitespace handling methods
#-----------------------------------------------------------------------

sub skip_ws { 
    # Most tokens aren't whitespace so they simply return $self.  If a $token 
    # reference is passed as the first argument then we update it to reference 
    # the new token.  This advances the token pointer.
    my ($self, $token) = @_;
    $$token = $self if $token;
    return $self;
}


sub next { 
    # next() returns the next token.  If a token reference is passed as the
    # first argument then it is also advanced to reference the next token.
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
    # Most tokens aren't delimiters so they simply return $self.  If a $token 
    # reference is passed as the first argument then we update it to reference
    # the new token.  This advances the token pointer.
    my ($self, $token) = @_;
    $$token = $self if $token;
    return $self;
}


sub next_skip_ws {
    # Delegate to the next token's skip_ws method
    $_[0]->[NEXT] && $_[0]->[NEXT]->skip_ws($_[1]) 
}



#-----------------------------------------------------------------------
# parser rule matching methods
#-----------------------------------------------------------------------

sub as_postfix {
    # Most things aren't postfix operators.  The only things that are 
    # are () [] and { }.  So in most cases as_postfix() skips any whitespace
    # and delegates straight onto as_postop() on the next non-whitespace 
    # token.
    shift->skip_ws($_[1])->as_postop(@_);
}


sub as_postop {
    # Args are: ($self, $lhs, $token, $scope, $prec)
    # Default behaviour (for non-postop tokens) is to return $lhs without 
    # advancing $token
    return $_[1];
}


sub as_block {
    my ($self, $token, $scope, $parent, $follow) = @_;
    $parent ||= $self;

    $self->debug("as_block()") if DEBUG;
 
    # Any expression can be a single expression block.  We specify the command 
    # keyword precedence level, CMD_PRECEDENCE, so that the expression will 
    # consume higher precedence operators, but stop at the next keyword.
    # e.g. 
    #    "if x a + 10 for y" is parsed as "(if x (a + 10)) for y".  
    #
    # Note that  the block (denoted by "(...)") ends at the 'for' keyword 
    # rather than consuming it rightwards as "(if x ((a + 10) for y)).  We use 
    # the FORCE flag to indicate that the precedence may be ignored for the 
    # first and only the first token (i.e. this one, $self).  That allows a 
    # command to follow as the single expression, e.g. if x fill y

    my $expr = $self->as_expr($token, $scope, CMD_PRECEDENCE, FORCE)
        || return;

    # if the parent defines any follow-on blocks (e.g. elsif/else for if)
    # then we look to see if the next token is one of them and activate it
    if ($follow && $$token->skip_ws($token)->in($follow)) {
        $self->debug("Found follow-on token: ", $$token->token) if DEBUG;
        return $$token->as_follow($expr, $token, $scope, $parent);
    }

    return $expr;
}


sub as_exprs {
    my ($self, $token, $scope, $prec, $force) = @_;
    my (@exprs, $expr);

    $token ||= do { my $this = $self; \$this };
 
    while ($expr = $$token->skip_delimiter($token)
                          ->as_expr($token, $scope, $prec)) {
        push(@exprs, $expr);
    }

    return undef
        unless @exprs || $force;

    return $self->[META]->[ELEMS]->construct(
        block => $self->[TOKEN], $self->[POS], \@exprs
    );
}


sub as_follow {
    my ($self, $block, $token, $scope, $parent) = @_;
    $parent ||= $block;
    return $self->error_msg( not_follow => $$token->[TOKEN], $parent->[TOKEN] );
}
    
    
#sub as_filename {
    # most elements aren't filenames
#    return BLANK;
#}



#-----------------------------------------------------------------------
# evaluation methods
#-----------------------------------------------------------------------

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


sub hash_values {
    $_[0]->debug_caller();
    $_[0]->error("called hash_values()");
    $_[0]->debug("hash_values() calling values()") if DEBUG;
    my $value = shift->value(@_);
    return ref $value eq HASH
        ? %$value
        : $value;
}


sub pair {
    shift->not_implemented;
}


sub pairs {
#    $_[SELF]->debug_caller;
    shift->not_implemented;
}


sub params {
    my ($self, $context, $posit) = @_;
    $posit ||= [ ];
    push(@$posit, $self->value($context));
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


sub signature {
    shift->bad_signature( bad_arg => @_ );
}


#-----------------------------------------------------------------------
# view / inspection methods
#-----------------------------------------------------------------------

sub view {
    $_[CONTEXT]->view_element($_[SELF]);
}


sub view_guts {
    # used mostly for debugging - see T::TT3::View::Tokens::Debug
    self   => refaddr $_[0],
    next   => refaddr $_[0]->[NEXT],
    branch => refaddr $_[0]->[BRANCH],
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

sub branch_text {
    my $self = shift;
    my $elem = $self->[BRANCH];
    my @text;
    while ($elem) {
        push(@text, $elem->[TOKEN]);
        $elem = $elem->[NEXT];
    }
#    $self->debug("BRANCHES: ",  $self->dump_data( $self->[BRANCH
    return @text
        ? join(BLANK, grep { defined } @text)
        : BLANK;
}



#-----------------------------------------------------------------------
# error handling
#-----------------------------------------------------------------------

sub bad_signature {
    my $self = shift;
    my $type = shift;
    my $name = shift;
    $name = $name ? "$name()" : 'function';
    $self->error_msg( "sign_$type" => $name, $self->source, @_ );
}


sub error_undef { 
    my $self = shift;
    $self->error_msg( undefined => $self->source, @_ );
}

sub error_undef_in { 
    my $self = shift;
    $self->error_msg( undefined_in => $self->source, @_ );
}


sub error_nan { 
    my $self = shift;
    $self->error_msg( nan => $self->source, @_ );
}


sub missing {
    my ($self, $what, $token) = @_;
    return $self->error_msg( 
        $$token->eof 
            ? (missing_for_eof => $what => $self->[TOKEN])
            : (missing_for     => $what => $self->[TOKEN] => $$token->[TOKEN])
    );
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

