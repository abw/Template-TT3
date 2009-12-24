package Template::TT3::Element;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    view      => 'element',
    utils     => 'self_params numlike refaddr is_object',
    slots     => 'meta _next token pos',
    import    => 'class CLASS',
    constants => ':elements :precedence CODE ARRAY HASH BLANK FORCE',
    constant  => {   
        # define a new base_type for the T::Base type() method to strip off
        # when generate a short type name for each subclass op
        base_id         => 'Template::TT3::Element',
        eof             => 0,
        # default names for parser arguments - see T::TT3::Element::Role::*Expr
        ARG_NAME        => 'name',
        ARG_EXPR        => 'expression',
        ARG_BLOCK       => 'block',
        EOF             => 'end of file',
    },
    alias => {
        # default parse method that decline
        parse_expr         => \&null,       # The usual case is to return 
        parse_word         => \&null,       # undef (which is all null() does)
        parse_args         => \&null,       # to decline a parse request.
        parse_pair         => \&null,
#       parse_dotop        => \&null,
        parse_filename     => \&null,
        parse_fragment     => \&null,
        parse_signature    => \&null,
        parse_infix        => \&reject,     # Special case returns LHS
        
        # default skip method don't skip but block on $self
        skip_separator     => \&accept,     # only separators skip here
        skip_delimiter     => \&accept,     # ditto for delimiters
        
        whitespace         => \&null,
        
        left_edge          => \&self,
        right_edge         => \&self,
        source             => 'token',
    };


our $MESSAGES = {
    # NOTE: these are being moved into Template::TT3::Base and a new 
    # error reporting mechansim (fail()) being put in place.
    
    # syntax errors
    missing_for     => "Missing %s for '%s'.  Got '%s'",
    missing_for_eof => "Missing %s for '%s'.  End of file reached.",
    missing_match   => "Missing '%s' to match '%s'",

    sign_bad_arg    => "Invalid argument in signature for %s: %s",
    sign_dup_arg    => "Duplicate argument in signature for %s: %s",
    sign_dup_sigil  => "Duplicate '<4>' argument in signature for %s: %s",

    # runtime data errors
    undef_data      => "Undefined value returned by expression: <1>",
    undef_expr      => "Undefined value in '<2>': <1>",
#    undef_dot       => "Undefined value in '<1>.<2>': <1>",
#    undef_method    => '"<2>" is not a valid <1> method in "<3>.<2>"', 
    nan             => "Non-numerical value '<2>' returned by expression: <1>",

    pairs_odd       => 'Cannot make pairs from an odd number (<2>) of items: <1>',
    pairs_bad       => 'Cannot make pairs from expression: %s',

    args_posit      => "Unexpected positional arguments in call to %s: %s",
    args_named      => "Unexpected named parameters in call to %s: %s",
    args_missing    => "Missing value for '<2>' named parameter in call to %s",

    bad_fragment    => "Mismatched fragment at end of '%s' block: %s",

    remains         => "Unparsed text: %s",
    
    resource_missing => 'Requested %s resource not found: %s',

    # stuff to cleanup/rationalise
#    bad_assign      => "Invalid assignment to expression: %s",
    bad_method      => "The %s() method is not implemented by %s.",
    not_follow      => "'%s' cannot follow '%s'",
    bad_assign      => "You cannot assign to %s",
#    no_pairs        => 'Unable to make pairs from expression: %s',
#    odd_pairs       => 'Cannot make pairs from an odd number of items (%s): %s',
    bad_pairs       => "Bare expression found where named parameters were expected: %s",
#    bad_args        => "Unexpected positional arguments passed to %s: %s",
#    bad_params      => "Unexpected named parameters passed to %s: %s",
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
    my $class = $self->[META]->[ELEMS]->element($type)
        || return $self->error_msg( invalid => element => $type );
    bless $self, $class;
}


sub append {
    my $self = shift;
    my $element;
    
    if (@_ == 1 && is_object(CLASS, $_[1])) {
        $element = shift;
        $self->debug("adding passed element to branch: $element") if DEBUG;
    }
    else {
        $element = $self->[META]->[ELEMS]->create(@_);
    }
        
    $self->[NEXT] = $element;
    
    return $element;
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
        $element = $self->[META]->[ELEMS]->create(@_);
    }
        
    # chase down the last node in any existing branch
    while ($tail->[BRANCH]) {
        $tail = $tail->[BRANCH];
    }
    
    $tail->[BRANCH] = $element;
    
    return $element;
}


sub extend {
    my $self = shift;
    $self->[TOKEN] .= join(BLANK, @_);
}


#-----------------------------------------------------------------------
# metadata methods
#-----------------------------------------------------------------------

sub lprec  { $_[0]->[META]->[LPREC] }
sub rprec  { $_[0]->[META]->[RPREC] }
sub length { CORE::length $_[0]->[TOKEN]  }


#-----------------------------------------------------------------------
# nullop methods to use for aliases
#-----------------------------------------------------------------------

sub null   { undef }
sub self   { $_[0] }
sub reject { $_[1] }


#-----------------------------------------------------------------------
# generic parse methods
#-----------------------------------------------------------------------

sub accept { 
    my ($self, $token) = @_;
    # set the $token to the current $self token
    $$token = $self if $token;
    return $self;
}


sub advance {
    my ($self, $token) = @_;
    # accept the current token and advance to the next one
    $$token = $self->[NEXT];
    return $self;
}


sub advance_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # accept the current token and advance to the next one
    $$token = $self->[NEXT];

    return $self;
}


sub is {
    # Check to see if the token matches that specified: 
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

        $match = { 
            map  { $_ => 1 } 
            grep { defined }
            @$match 
        } if ref $match eq ARRAY;
            
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


sub next_skip_ws {
    # Delegate to the next token's skip_ws method
    $_[0]->[NEXT] && $_[0]->[NEXT]->skip_ws($_[1]) 
}


sub skip_ws { 
    # Most tokens aren't whitespace so they simply return $self.  If a $token 
    # reference is passed as the first argument then we update it to reference 
    # the new token.  This advances the token pointer.
    my ($self, $token) = @_;
    $$token = $self if $token;
    return $self;
}



#-----------------------------------------------------------------------
# parser rule matching methods
#-----------------------------------------------------------------------

sub parse {
    my $self    = shift;
    my $scope   = shift;
    my $token   = \$self;
    my $block   = $self->parse_block($token, $scope, 0, 1);
    $$token->finish;
    return $block;
}
    

sub parse_postfix {
    # Most things aren't postfix operators.  The only things that are 
    # are () [] and { }.  So in most cases parse_postfix() skips any whitespace
    # and delegates straight onto parse_infix() on the next non-whitespace 
    # token.
    shift->skip_ws($_[1])->parse_infix(@_);
}


sub parse_body {
    my ($self, $token, $scope, $parent, $follow) = @_;
    $parent ||= $self;

    $self->debug("parse_body()") if DEBUG;
 
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

    my $expr = $self->parse_expr($token, $scope, CMD_PRECEDENCE, FORCE)
        || return;

    # if the parent defines any follow-on blocks (e.g. elsif/else for if)
    # then we look to see if the next token is one of them and activate it
    if ($follow && $$token->skip_ws($token)->in($follow)) {
        $self->debug("Found follow-on token: ", $$token->token) if DEBUG;
        return $$token->parse_follow($expr, $token, $scope, $parent);
    }

    # ...and we pass on down through the valley
    return $$token->skip_ws->parse_infix($expr, $token, $scope, $self->[META]->[LPREC]);
}


sub parse_exprs {
    my ($self, $token, $scope, $prec, $force) = @_;
    my (@exprs, $expr);

# Do we ever get called without args?  
#   $token ||= do { my $this = $self; \$this };

    $self->debug(
        ">> parse_expr() starting, first token is $$token: ", 
        $$token->source
    ) if DEBUG;
 
    while ($expr = $$token->skip_delimiter($token)
                          ->parse_expr($token, $scope, $prec)) {
        push(@exprs, $expr);

        $self->debug(
            "++ parsed expr: $expr  ==> ", 
            $expr->source
        ) if DEBUG;
    }

    $self->debug(
        "<< parse_expr() ended, next token is $$token: ", 
        $$token->[TOKEN]
    ) if DEBUG;

    return @exprs || $force
        ? \@exprs
        : undef;
}


sub parse_block {
    my $self  = shift;
    my $exprs = $self->parse_exprs(@_) || return;

    return $self->[META]->[ELEMS]->create(
        block => $self->[TOKEN], $self->[POS], $exprs
    );
}


sub parse_pairs {
    my ($self, $token, $scope, $prec, $force) = @_;
    my (@exprs, $expr);
    
    $prec = ARG_PRECEDENCE
        unless defined $prec;

    # Just like parse_exprs() except that we only skip over separators
    # and not delimiters.  We also use the explicit ARG_PRECEDENCE (defined
    # to be the same as '=' so that the process stops on keywords, allowing
    # us to write things like "with x=10 y=20 fill blah" and have the 'fill'
    # be recognised as the end of the parameters.
    
    while ($expr = $$token->skip_separator($token)
                          ->parse_pair($token, $scope, $prec)) {
        $self->debug("parsed paired expr: ", $expr->source) if DEBUG;
        push(@exprs, $expr);
    }
    
    return undef
        unless @exprs || $force;

    return $self->[META]->[ELEMS]->create(
        block => $self->[TOKEN], $self->[POS], \@exprs
    );
}


sub parse_dotop {
    my $self = shift;
    $self->debug("parse_dotop()") if DEBUG;
    # keywords, terminators, operators, etc., that are alphanumeric (e.g. 
    # 'in', 'or', 'and', etc., automatically downgrade themselves to simple 
    # words when used after a dot
    return $self->[TOKEN] =~ /^\w+$/
        ? $self->become('word')->parse_dotop(@_)
        : undef;
}


sub parse_follow {
    my ($self, $block, $token, $scope, $parent) = @_;
    $parent ||= $block;
    return $self->error_msg( not_follow => $$token->[TOKEN], $parent->[TOKEN] );
}
    


#-----------------------------------------------------------------------
# Methods to coerce parsed element expressions to a particular role.
# The default behaviour is to throw a syntax error if they can't fulfill
# the role.  Those that can fulfill a role should implement their own 
# versions of the relevant method.
#-----------------------------------------------------------------------

sub as_lvalue {
    my ($self, $op, $rhs, $scope) = @_;
    return $self->syntax_error_msg( $self, bad_assign => $self->source );
}


sub as_pair {
    my $self = shift;
    $self->syntax_error_msg( $self, bad_pairs => $self->source );
}


sub in_signature {
    shift->signature_error( bad_arg => @_ );
}




#-----------------------------------------------------------------------
# evaluation methods
#-----------------------------------------------------------------------

sub name {
    # TODO: raise a proper error
    shift->not_implemented('in element base class (TODO)');
}

sub text {
    shift->value(@_);
}


sub number {
    my $self = shift;
    my $text = $self->value(@_);

    return 
        ! defined $text ? $self->undefined_error
      : ! numlike $text ? $self->nan_error($text)
      : $text;
}


sub value {
    shift->not_implemented('in element base class');
}


sub maybe {
    shift->value(@_);
}


sub variable {
    shift->not_implemented('in element base class');
}


sub values {
    shift->value(@_);
}


sub list_values {
    my $value = shift->value(@_);
    return ref $value eq ARRAY
        ? @$value
        : $value;
}


sub OLD_hash_values {
    $_[0]->debug_caller();
    $_[0]->error("called hash_values()");
    $_[0]->debug("hash_values() calling values()") if DEBUG;
    my $value = shift->value(@_);
    return ref $value eq HASH
        ? %$value
        : $value;
}


sub params {
    my ($self, $context, $posit) = @_;
    $posit ||= [ ];
    push(@$posit, $self->value($context, $self));
}


sub pairs {
    my $self = shift;
    $self->syntax_error_msg( $self, bad_pairs => $self->source );
}


sub fetch_template {
    my ($self, $name, $context, $scope) = @_;
    my ($blocks, $block);
    
    my @args = ( name => $name );

    # Before asking for the template, we do a local lookup for a block
    # in this scope.  If we find an entry then we use that single item
    # as an argument to the context's template() method.
    if ($scope && ($blocks = $scope->{ blocks })) {
        if ($block = $blocks->{ $name }) {
            @args = ($block);
            $self->debug(
                "found block for $name: ", 
                $self->dump_data($block)
            ) if DEBUG;
        }
    }
    
    $self->debug(
        "asking context for $name template: ", 
        $self->dump_data(\@args)
    ) if DEBUG;

    return $context->template(@args)
        || $self->fail_resource_missing( template => $name );
}


#-----------------------------------------------------------------------
# view / inspection methods
#-----------------------------------------------------------------------


sub tree {
    my $self = shift;
    return $self->[META]->[ELEMS]->hub->types->create(
        tree => { root => $self }
    );
}


sub sexpr {
    shift->tree->view_sexpr;
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



# TODO: tweak T::TT3::Class to make this declarable

sub type {
    my $self = shift;
    my $id   = $self->class->id;
#    $class =~ s/([^:]*)$/$1/;
    return lc $id;
}


sub finish {
    my $self = shift;
    my $rest = $self->remaining_text;
    
    return $self->error_msg(
        remains => $rest
    ) if defined $rest && CORE::length $rest;
}



#-----------------------------------------------------------------------
# new error handling methods
#-----------------------------------------------------------------------

sub fail {
    my $self = shift;
    my $name = shift;
    my $type = $name =~ /^([[:alnum:]]+)_/ ? $1 : $name;
    my $text = $self->message($name, @_);
    my $posn = $self->pos;
    return $self->token_error( $type, $self, $text);
}


sub fail_src {
    my $self = shift;
    return $self->fail(@_, $self->source);
}


sub fail_data { 
    my $self = shift;
    my $name = 'data_' . shift;
    $self->fail($name, @_);
}


sub fail_data_undef { 
    my $self = shift;
    $self->fail( data_undef => $self->source );
}


#-----------------------------------------------------------------------
# Older error handling method - see also methods in Template::TT3::Base
# TODO: clean all this up.  There are too many confusing methods.
#-----------------------------------------------------------------------


sub fail_missing {
    my ($self, $what, $token) = @_;
    $token ||= \$self;
    $self->debug("[$self] missing [$what] [$token = $self->[TOKEN]]") if DEBUG;
    return $self->syntax_error_msg(
        $$token,
        $$token->eof 
            ? (missing_for_eof => $what => $self->[TOKEN])
            : (missing_for     => $what => $self->[TOKEN] => $$token->[TOKEN])
    );
}




sub fail_pairs { 
    my ($self, $what, $source, @args) = @_;
    
    return $self->syntax_error_msg(
        $self,
        "pairs_$what" => $source || $self->source, @args
    );
}


sub fail_args { 
    my ($self, $what, $source, @args) = @_;
    
    return $self->syntax_error_msg(
        $self,
        "args_$what" => $source || $self->source, @args
    );
}


sub fail_resource { 
    my ($self, $what, $source, @args) = @_;
    
    return $self->resource_error_msg(
        $self,
        "resource_$what" => $source || $self->source, @args
    );
}


sub fail_syntax { 
    my $self = shift;
    return $self->syntax_error_msg($self, @_);
}


sub fail_pairs_odd {
    my $self = shift;
    $self->fail_pairs( odd => $self->source, @_ );
}


sub fail_pairs_bad {
    my $self = shift;
    $self->fail_pairs( bad => @_ );
}


sub fail_args_posit {
    my $self = shift;
#    $self->fail_args( posit => $self->source, @_ );
    $self->fail_args( posit => @_ );
}


sub fail_args_named {
    my $self = shift;
#    $self->fail_args( named => $self->source, @_ );
    $self->fail_args( named => @_ );
}


sub fail_args_missing {
    my $self = shift;
#    $self->fail_args( missing => $self->source, @_ );
    $self->fail_args( missing => @_ );
}


sub fail_resource_missing {
    shift->fail_resource( missing => @_ );
}

sub fail_template_missing {
    shift->fail_resource( missing => template => @_ );
}


sub signature_error {
    my $self = shift;
    my $type = shift;
    my $name = shift;
    $name = $name ? "$name()" : 'function';
#    $self->error_msg( "sign_$type" => $name, $self->source, @_ );

    return $self->syntax_error_msg(
        $self,
        "sign_$type" => $name, $self->source, @_ 
    );
}




sub nan_error { 
    my $self = shift;
    $self->error_msg( nan => $self->source, @_ );
}





1;

__END__


# methods to return the leftmost and rightmost leaf node of a subtree
*left_edge  = \&self;
*right_edge = \&self;


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



1;

__END__

=head1 NAME

Template:TT3::Element - base class for all elements in a template tree

=head1 DESCRIPTION

This module implements a common base class for all elements in a template 
tree.  Everything in a template, and I mean I<everything> is represented 
as an element in a parse tree.  

This documentation describes the structure of the element object (a blessed
array reference with a limited number of pre-defined slots), the process by
which elements are created (scanning and parsing) and the hierarchy of 
element subclasses that collectively implement the template grammar.  It is
aimed at a technical audience interested in modifying, extending, or simply
understanding the inner workings of TT3.  Non-technical readers may wish to
retire at this point and avail themselves of the leisure facilities.

=head1 COMPILING TEMPLATES

=head2 Things You Need to Know

Before we get started there are some basic things you need to know for 
the examples to make sense.

=head3 Element Structure

Elements are implemented as blessed array references. Arrays are smaller and
faster than hash arrays, the more traditional choice for basing objects on.

Speed is absolutely of the essence in parsing and evaluating elements.  For
that reason we are prepared to sacrifice a little readability for the sake
of speed.  To make things more bearable, we define a number of constants
that are hard-coded to numerical values representing the different array
elements.  We call these element I<slots>.

    $self->[4];         # Huh?  What's that then?
    
    $self->[EXPR];      # Oh right, it's the expression slot

The first four slots are the same for all element types:

    [META, NEXT, TOKEN POS]

The C<META>, C<NEXT>, C<TOKEN> and C<POS> constants are defined in the
L<Template::TT3::Constants> module as the C<:elements> tag set.

    use Template::TT3::Constants ':elements';

TT3 modules use L<Template::TT3::Class> to import these constants, among
other things.  For example:

    package Template::TT3::SomeModule;
    
    use Template::TT3::Class
        version   => 3.14,
        constants => ':elements';

The C<META> slot contains a reference to a data structure that is shared
between all instances of the same element type.  The most common use for 
this is to look up operator precedence levels.

    my $left_precedence = $self->[META]->[LPREC];

Elements can access the element factory (a L<Template::TT3::Elements> object)
through the C<META> slot in case they need to generate any other elements on
the fly.

    my $factory = $self->[META]->[ELEMS];

The C<NEXT> slot contains a reference to the next token in the list.  This
is the original list of tokens as they were scanned from the source document 
in strict order.  This is always preserved so that we can reconstitute the
original template text at any time (e.g. for error reporting, debugging,
template transformation, and so on).

The C<TOKEN> slot contains the original text of the element token as it was
scanned from the source template. This should also be preserved in its
original form. The only exception to that would be if you're writing code to
deliberately transform the template in some way, e.g. to rename a variable
as part of an automatic re-factoring process.  In which case, this is what
you need to change.  But in normal use, it remains constant.

The C<POS> is the character position (as reported by C<pos()>) of the source
token in the template document.  Again, this shouldn't ever change in normal
use.

The remaining slots vary from element to element.  Unary operators use
C<EXPR> (4) to store a reference to the target expression.  Elements that
expect a block to follow (e.g. C<for>, C<if>, etc) store that in C<BLOCK>
(5).  Binary operators use different aliases to those same slots: C<LHS> (4)
and C<RHS> (5), but the names are just syntactic sugar.  Elements that 
may have arguments (variables, and certain commands like C<with>) use C<ARGS>
(6) to store those arguments.  The C<BRANCH> slot (7) is used by elements that
can have an optional branch, most notably C<if> that can be followed by an
C<elsif> or C<else> branch.

=head3 Keeping Track of the Current Element

We need to keep track of the current element during scanning and parsing.
We do this by using a reference to an element.  We use the C<$token> variable
for this purpose (rather than C<$element>) to remind us that it's a reference
to the current scanning/parsing token (which happens to be an element object).

    # $element is an element object
    $token = \$element;

We pass this C<$token> reference around between methods so that any of them
can advance the current token by updating the element it references.  For 
example, to move the token onto the next element:

    $$token = $$token->[NEXT];

=head3 Parsing Method Arguments

Element parsing methods fall into three broad categories: those that work
on expressions, those that work on blocks, and all the others.  Methods that
work on expressions expect the following arguments:

    $$token->parse_expr($token, $scope, $prec, $force);

Note that C<$token> is a I<reference> to the current token (element) that
we're looking at. We have to de-reference it (C<$$>) to get the element object
before we can call the L<parse_expr()> method against it. 

The first argument passed to the method, C<$token>, is this reference to the
current token. We use the extra level of indirection so that methods can
advanced the current token by updating this reference.

The second argument, C<$scope>, is a reference to a L<Template::TT3::Scope>
object.  At the time of writing this isn't used (much, if at all).  It's
there for when we want to implement lexical variables, constant folding, 
and other compile-time magic.

The third argument, C<$prec>, is an optional precedence level.  This is used
for resolving operator precedences.

The fourth argument, C<$force>, is an optional argument that is used to 
temporarily over-ride precedence levels.  This is set true for expressions
that appear on the right side of assignment operators, for example.

    foo = fill bar

The C<fill> command has a lower precedence than the C<=> operator so it
would usually decline a call to its L<parse_expr()> method.  The C<$force>
flag tells it to stop being so silly and just get on with it.  However,
the C<fill> element will pass the original C<$prec> value onto any 
tokens that it delegates to so that things Just Work[tm] in terms of 
subsequent operators parsing themselves appropriately.

In some cases we need to pass an extra element to a method. For example, the
C<parse_infix()> method is called to parse infix operators and requires a
reference to the token immediately preceding it. In this case the additional
token goes right at the front.

    $$token->parse_infix($lhs, $token, $scope, $parent, $follow)

Methods that work on blocks expect the following arguments:

    $$token->parse_body($token, $scope, $parent, $follow)

The first two arguments are the same as for expression parsing methods.

C<$parent> is the parent of the block. This is mainly used for error reporting.
e.g. in the block hanging off an C<if> element any errors should be reported
as being in the parent "if" block.

C<$follow> is a reference to a hash array of keywords that can follow the
block. This is used by C<if> (and others) to detect things like C<elsif> and
C<else> branches.

Methods falling into the third category don't follow any particular pattern
in terms of what arguments they accept.  However, we try to keep them in an
order which corresponds to the above wherever possible.  So if a method 
expects a token then it will always be passed as the first argument.  If 
it expects a scope, then that will be second, and so on.

=head2 SCANNING

The L<Template::TT3::Scanner> is responsible for scanning the template 
source and identifying the blocks of plain text and embedded template tags.
In this first scanning phase, the emphasis is on identifying the separate
I<tokens> in the document and creating elements to represent them.  A simple
ordered list of element objects is created.  Each element object contains
the source token (i.e. the literal text that was scanned) and its position
(character offset) in the source template.  It also has a reference to the 
token that immediately follows it.  In other words, we create a single linked
list of tokens with each token pointing forwards to the next token.

For example, consider this simple template:

    Hello [% name %]

The scanner first recognises the chunk of text at the beginning and creates a
text element (L<Template::TT3::Element::Text>) to represent it. Elements are
implemented as blessed array references (rather than the traditional blessed
hash reference) for the sake of memory efficiency and execution speed. For the
purpose of demonstration we'll show a simplified representation of this text
element as:

    # type, token, position 
    [ text => 'Hello ', 0 ]         # Template::TT3::Element::Text

Following the text we have the C<[%> start token.  The scanner will recognise
any number of different tags in a template.  It effectively constructs a 
regular expression that matches a chunk of text up to the first tag start 
token.  In pseudo-regex form it looks like this:

    / \G ( .*? ) ( $start1 | $start2 | ... | $startn ) /

Note the C<\G> marker at the start of the pattern. This indicates that we
always want to start scanning at the current global regex matching point. In
other words, we always continue from where we left off.  This allows us to 
scan the template source non-destructively.  

Now that it has identified a tag start token, it looks up the tag object 
(a subclass of L<Template::TT3::Tag>) corresponding to that token and asks
it to continue scanning from that point on.  Note that we must pass it a 
I<reference> to the source text rather than a I<copy> of the source text.
This is so that the tag can use the same C<\G> marker to continue parsing
from the current point.  Passing around a reference to the text is also 
more efficient as it avoids copy the string each time.

So the tag gets a copy of the string and takes over the tokenising process.
Different tags can implement different tokenising rules, but we'll just 
concentrate on what the default TT3 tag does for now.  In this example, there
is just a single word in the tag, C<name>.  However, we don't overlook the 
start tag, end tag and any intervening whitespace.  We also create tokens 
to represent them:

    [ tag_start  => '[%',     6 ]   # Template::TT3::Element::TagStart
    [ whitespace => ' ',      8 ]   # Template::TT3::Element::Whitespace
    [ word       => 'name',   9 ]   # Template::TT3::Element::Word
    [ whitespace => ' ',     13 ]   # Template::TT3::Element::Whitespace
    [ tag_end    => '%]',    14 ]   # Template::TT3::Element::TagEnd

Once the tag has identified its own end token it returns control to the 
scanner.  We're now at the end of the template so there's nothing else for
the scanner to add.  Before it returns, it adds a final token to the end of
the list to indicate the end of file.  The full set of elements generated to 
represent this is template is:

    [ text       => 'Hello ', 0 ]   # Template::TT3::Element::Text
    [ tag_start  => '[%',     6 ]   # Template::TT3::Element::TagStart
    [ whitespace => ' ',      8 ]   # Template::TT3::Element::Whitespace
    [ word       => 'name',   9 ]   # Template::TT3::Element::Word
    [ whitespace => ' ',     13 ]   # Template::TT3::Element::Whitespace
    [ tag_end    => '%]',    14 ]   # Template::TT3::Element::TagEnd
    [ EOF        => 'EOF',   16 ]   # Template::TT3::Element::Eof

Remember that each token also has a reference to the next token in the list,
although that isn't show here.

The benefit of creating elements to represent all the tokens in the source,
including all the things that we normally don't care about like whitespace,
comments, tag start/end tokens, and so on, is that we can regenerate the
original template source at any time. This is invaluable for debugging
purposes. It also makes it possible to transform the template in various of
interesting ways. For example, we can easily generate HTML complete with
syntax highlighting. Or we can automatically parse a template, refactor it in
some way (e.g. renaming a variable) and then save the modified template source
back to disk.

TODO: There should be an optimisation option to ignore whitespace tokens
if you're in a real hurry and know you're never going to need them.

TODO: I'm also planning to automatically consume whitespace into the tag
start/end tokens (perhaps as an optional thing if I can think of any reason
why someone might not want that). You would end up with a shorter token list: 

    [ text       => 'Hello ', 0 ]   # Template::TT3::Element::Text
    [ tag_start  => '[% ',    6 ]   # Template::TT3::Element::TagStart
    [ word       => 'name',   9 ]   # Template::TT3::Element::Word
    [ tag_end    => ' %]',   14 ]   # Template::TT3::Element::TagEnd
    [ EOF        => 'EOF',   16 ]   # Template::TT3::Element::Eof

=head2 PARSING

Once we have a list of tokens we can parse them into expressions. But first
let's clear up some terminology. 

When we talk about I<tokens> we're referring to the individual
blocks of characters that we scanned from the template document: 'Hello ',
'[%', ' ', and so on. However, they're represented internally as I<element>
objects. So tokens are elements and elements are tokens.  

When we talk about I<expressions> we're referring to particular combinations
of tokens that have a specific meaning.  This could be a complex expression
like the following:

    a + b * c + (d / e * 100)

Or it could be something degeneratively simple like this:

    a

We also treat raw text chunks as simple expressions.  In fact, we treat
everything as an expression.  A template is little more than a sequence
of expressions.  To process the template, we simply evaluate each expression
and glue the resulting text into a single string.  

Expressions are represented as trees of tokens. In the simple case an
expression can be a solitary token. So expressions are tokens, which means
they are also elements. Expressions are tokens are elements. They're just
organised in a different way. Organising the raw stream of tokens into trees
of expressions is the process of I<parsing> the template. Note that we don't
change the original linear sequence of tokens. Rather, we add additional links
to describe the way that different tokens are connected together.

The first thing we need to consider is how we get rid of the whitespace
tokens. Well that's easy. If you have an C<$element> you can call its L<skip_ws()>
method.  

    $element = $element->skip_ws;

Of if you're using a reference to the element in C<$token>:

    $$token = $$token->skip_ws;

If the C<$element> I<isn't> a whitespace token then the method will return
C<$self>. In other words, no change. If it I<is> a whitespace token, then the
token calls L<skip_ws()> on the token immediately following it (i.e. the next
token). Thus, the L<skip_ws()> method will merrily skip through any number of
whitespace tokens and return a reference to the first non-whitespace token.

You can also pass a reference to the current token as an argument. In this
case the L<skip_ws()> method will automatically update your C<$element> variable
to reference the first non-whitespace token following.

    $element->skip_ws(\$element);

Many of the element parsing methods expect a reference to the current
token as the first argument.  This is effectively the "current token" pointer
and parsing methods will automatically advance it as they consume tokens.
It's optional for the L<skip_ws()> method and one or two other related methods, 
but it's mandatory for anything else that can advance the current parsing 
position.  Because of this, all the methods assume that C<$token> is already 
a reference to an element, so the code looks more like this:

    $$token->skip_ws($token);

Having called L<skip_ws()> to skip over any whitespace, we can now call
L<parse_expr()> on the token that follows in.  We'll explain it in detail 
in a moment, but for now you just need to know that it returns an 
expression.  

    $expr = $$token->skip_ws->parse_expr($token, $scope)

As it happens, you don't need to explicitly call the L<skip_ws()> method
before calling L<parse_expr()>.  All whitespace tokens implement a 
L<parse_expr()> method that does something like this:

    sub parse_expr {
        my $self = shift;
        $self->next->parse_expr(@_);
    }

Whitespace tokens "know" that whitespace is allowed before expressions, so
they simply skip over themselves and call L<parse_expr()> on the next token.
If that's also a whitespace token then it will delegate onto its next token,
and so on. So given any token, we can simply ask it to parse an expression and
let it take care of skipping over whitespace:

    $expr = $$token->parse_expr($token, $scope);

Lets look at our simple template again:

    Hello [% name %]

The first token is a simple text token. It has an equally simple
L<parse_expr()> method that advances the C<$token> reference and
returns itself.

    sub parse_expr {
        my ($self, $token) = @_;
        $$token = $self->[NEXT];
        return $self;
    }

Yay!  We've got our first expression.  Furthermore, our C<$token> reference
now points at the token immediately following the text token.  So we can 
ask that to return itself as an expression.

    $expr = $$token->parse_expr($token, $scope);

In this case the token is the C<[%> tag start token.  But that's just a 
special kind of whitespace so it immediately skips over itself and asks the
next token to C<parse_expr()>.  Guess what?  That's whitespace too!  But
it all gets taken care of automatically.  The next non-whitespace token is the
C<name> word.  When words appear in expressions like this they're treated as
variable names.  So the word token also "knows" that it's an expression and
can advanced the token pointer and return itself.

So to parse a sequence of expressions we can write something like this:

    while ($expr = $$token->parse_expr($token, $scope)) {
        push(@exprs, $expr);
    }

Well, almost.  We also have to look out for delimiters like C<;> that are
allowed (but not necessarily required) between statements:

    [% foo; bar %]

To avoid complicating matters, we'll just skip to the fact that there's a
L<parse_exprs()> method which will parse a sequence of expressions.

    $exprs = $$token->parse_exprs($token, $scope);

There are a few element that aren't expressions. We already mentioned the C<;>
delimiter. Tag end tokens like C<%]> are also considered a special kind of
delimiter.  Other I<terminator> tokens like C<)>, C<]>, C<}> and C<end> are
also non-expressions.  If one of these is encountered then C<parse_exprs()>
will stop and return all the expressions that it's collected so far.

=head2 OPERATOR PRECEDENCE

Operator precedence is used to ensure that binary operators are correctly
grouped together.  Consider this simple expression:

    a + b * c

The mathematical convention is that C<*> has a higher precedence than C<+>.
In practice that means that you do the multiplication first and then the 
addition:

    a + (b * c)

Let's look at what happens when you call the C<parse_expr()> method against the
C<a> token.  The word token is a valid expression by itself, but instead of
just returning itself, it calls the C<parse_infix()> method on the token
following it.  It passes itself as the first argument followed by the usual
C<$token> and C<$scope> arguments.  The third argument is a precedence level.
This is the key to operator precedence parsing.

    sub parse_expr {
        my ($self, $token, $scope, $prec) = @_;
        
        # advance token
        $$token = $self->[NEXT];
        
        return $token->parse_infix($self, $token, $scope, $prec);
    }

Let's first consider what happens if the next token I<isn't> an infix operator
(or a whitespace token which we'll assume gets skipped automatically).  In
this case, the default L<parse_infix()> method returns C<$lhs>.  In other
words, we get the C<a> word token passed back as an expression.

If the next token I<is> an infix operator, like C<+> in our example, then 
it stores the left hand expression in its C<LHS> slot.  It then calls
the L<parse_expr()> on the next token (C<b>) to return an expression to 
become its C<RHS>.  

    sub parse_infix {
        my ($self, $lhs, $token, $scope) = @_;
        
        # save the LHS
        $self->[LHS] = $lhs;
        
        # advance token passed the operator
        $$token = $self->[NEXT];
        
        # parse an expression on the RHS
        $self->[RHS] = $$token->parse_expr($token, $scope);
        
        return $self;
    }

To implement operator precedence we add an extra argument.  

    sub parse_infix {
        my ($self, $lhs, $token, $scope, $prec) = @_;

Each operator has it's own precedence level (defined in
C<$self-E<gt>[META]-E<gt>[LPREC]>). If the C<$prec> argument is specified and
it is I<higher> that the operator's own precedence then the method returns the
C<$lhs> immediately.

        return $lhs
            if $prec && $prec > $self->[META]->[LPREC];

If the operator's precedence is higher, or if C<$prec> is undefined then the
method continues.  When it calls the C<parse_expr()> method to fetch an 
expression for the C<RHS> it passes its own precedence level as the 
extra argument. 

        $self->[RHS] = $$token->parse_expr(
            $token, $scope, $self->[META]->[LPREC]
        );

The end result is that if we have a low precedence operator followed by
a higher precedence operator, like this:

    a + b * c

Then the higher precedence C<*> completes itself first before returning
back to the C<+> operator.

    a + (b * c)

If instead we have a high precedence operator coming first:

    a * b + c

Then the second, lower precedence operator, will return immediately allow
the first operator to complete itself first.

    (a * b) + c

To complete things, we need to change the final C<return> to be an additional
call to C<parse_infix()> in case there are any other lower-precedence infix 
operators following that have yielded to let us go first.

TODO: more on this

=head1 CONSTRUCTION AND CONFIGURATION METHODS

NOTE: This documentation is incomplete.

=head2 new()

Simple constructor blesses all arguments into list based object.

=head2 init_meta()

Internal method for initialising the element metadata that is referenced
via the C<META> slot.

=head2 constructor() 

Returns a constructor function.

=head2 configuration($config) 

Stub configuration method for subclasses to redefine if they need to

=head2 become($type)

Used to change an element into a different type.

=head2 append($element)

Used to append a new element to the current element.  You can either
pass a reference to an element object, or the arguments required to 
construct one.

    $element->append( text => 'Hello', 42 );      # type, token, position

=head2 branch($element)

This is similar to the L<append()> method but attaches the new token to 
its C<BRANCH> slot instead of the usual C<NEXT> slot. 

    $element->branch( text => 'Hello', 42 );      # type, token, position

=head2 extend($token)

Used to append additional content to the scanned token.

    my $element = $tokens->append( text => 'Hello ' );
    $element->extend('World');
    
    print $element->token;      # Hello World

=head1 ACCESSOR METHODS

=head2 meta()

This returns the metadata entry in the C<META> slot.

=head2 next(\$element)

This returns the element in the C<NEXT> slot that indicate the next token in
the template source. If a token reference is passed as an argument then it
will also be updated to reference the next token.  The following are equivalent:

    $element = $element->next;
    
    $element->next(\$element);

If C<$token> is a reference to an element (as is usually the case) then you
would write:

    $$token->next($token);

=head2 token()

This returns the original text of the element token.

    print $element->token;

=head2 pos()

This return the character offset of the start of the token in the template
source.

    print " at offset ", $element->pos;

=head2 self()

This method simply returns the first argument, the element object itself.
It exists only to provide a useful no-op method to create aliases to.

=head2 lprec()

Returns the leftward precedence of the element.  This is the value stored
in the C<LPREC> slot of the C<META> data.  The leftward precedence is 
used for all postfix and infix operators.

=head2 rprec()

Returns the rightward precedence of the element.  This is the value stored
in the C<RPREC> slot of the C<META> data.  The rightward precedence is 
used for all prefix operators.

=head1 PARSING METHODS

The following methods are used to parse a stream of token elements into a 
tree of expressions.

=head2 null()

This method simply returns undef.  Like L<self()> it exists only for creating
no-op method aliases.  For example, the default L<parse_word()> method is 
an alias to C<null()>, effectively indicating that the element can't be 
parsed as a word.  Elements that are words, or can be interpreted as words
should define their own L<parse_word()> method to do something meaningful.

=head2 reject($lhs, ...)

This method of convenience simply returns the first argument.  It can be used
as syntactic sugar for elements that decline a particular role.  For example,
elements that aren't infix operators should implement a L<parse_infix()>
method like this:

    sub parse_infix {
        my ($self, $lhs, $token, $scope, $prec) = @_;
        
        # we're not an infix operator so we just return the $lhs
        return $lhs;
    }

However, it's a lot easier to define L<parse_infix()> as an alias to the 
C<reject()> method.

    package Template::TT3::Element::SomeElement;
    
    use Template::TT3::Class
        base  => 'Template::TT3::Element',
        alias = {
            parse_infix => 'reject',
        };

The L<alias()|Template::TT3::Class/alias()> method will locate the 
C<reject()> method defined in the C<Template::TT3::Element> base class
and define C<parse_infix()> as a local alias to it.

In fact, you don't need to do this at all because the
C<Template::TT3::Element> base class already defines L<parse_infix()> as an
alias to L<reject()>. However, you might be using another base class that
defines a different L<parse_infix()> method that you want to over-ride with
the C<reject()> method.

=head2 advance(\$element)

This is another simple method of convenience which advances the token
reference to the next element and returns itself.

    sub parse_expr {
        my ($self, $token) = @_;
        return $self->accept($token);
    }

This is short-hand for:

    sub parse_expr {
        my ($self, $token) = @_;
        $$token = $self->[NEXT];
        return $self;
    }

=head2 is($match,\$element)

This method can be used to test if an element's token matches a particular
value. So instead of writing something like this:

    if ($element->token eq 'hello') {
        # ...
    }

You can write:

    if ($element->is('hello')) {
        # ...
    }

When you've matched successfully a token you usually want to do something
meaningful and move onto the next token.  In this example, C<$token> is
a reference to the current element:

    if ($$token->is('hello')) {
        # do something meaningful
        print "Hello back to you!";

        # advance to the next token
        $$token->next($token);
    }
    else {
        die "Sorry, I don't understand '", $$token->token, "\n";
    }

The C<is()> method accepts a reference to the current element as an optional
second argument. If the match is successful then the reference will be
advanced to point to the next token. Thus the above example can be written
more succinctly as:

    if ($$token->is('hello', $token)) {
        # do something meaningful
        print "Hello back to you!";
    }
    else {
        die "Sorry, I don't understand '", $$token->token, "\n";
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

    if ($response = $$token->in($matches)) {
        print $response;
    }
    else {
        die "Sorry, I don't understand '", $$token->token, "\n";
    }

As with C<is()>, you can pass a reference to the current token as the 
optional second argument.  If the match is successful then the reference
will be advanced to point to the next token.

=head2 skip_ws(\$element)

Used to skip over any whitespace tokens. 

    $expr = $$token->skip_ws->parse_expr($token, $scope);

=head2 next_skip_ws(\$element)

Advances to the next token and then skips any whitespace

    $expr = $$token->next_skip_ws->parse_expr($token, $scope);

This is equivalent to:

    $expr = $$token->next->skip_ws->parse_expr($token, $scope);

=head2 skip_delimiter(\$element)

Used to skip over any delimiter tokens.  These include the semi-colon
C<;> and any tag end tokens.

=head2 parse_expr(\$element, $scope, $precedence, $force)

This method parses an expression.  It returns C<undef> if the element
cannot be parsed as an expression.

    my $expr = $$token->parse_expr($token);

=head2 parse_exprs(\$element, $scope, $precedence, $force)

This method parses a sequence of expressions separated by optional 
delimiters (semi-colons and tag end tokens).

    my $list = $$token->parse_exprs($token, $scope, $prec)
        || die "No expressions!";

The method returns a reference to a list of parsed expression elements. If no
expressions can be parsed then it returns C<undef>. The optional C<$force>
argument can be set to a true value to force it to always return a list
reference, even if no expressions were parsed. This is required to parse
expressions inside constructs that can be empty. e.g. empty lists (C<[ ]>),
hash arrays (C<{ }>), argument lists (C<foo()>), etc.

    # always returns a list reference with the $force option set
    my $list = $$token->parse_exprs($token, $scope, $prec, 1);
    
    foreach my $expr (@$list) {
        print "parsed expression: ", $expr->source, "\n";
    }

=head2 parse_block()

This method is a wrapper around L<parse_exprs()> that creates a block 
element (L<Template::TT3::Element::Block>) to represent the list of 
expressions.  

    my $block = $$token->parse_block($token, $scope, $prec, 1);
    
    print "parsed block: ", $block->source, "\n";

=head2 parse_body()

This method is the one usually called by command elements that expect a 
block I<or> a single expression to follow them.  For example, the C<if>
command can be written as any of the following:
    
    [% if x %][% y %][% end %]

    [% if x; y; end %]

    [% if x { y } %]

    [% if x y %]

The delimiter elements, C<%]> and C<;>, respond to the C<parse_body()> method
call by parsing a block of expressions up to the terminating C<end> token. The
left brace element, C<{>, responds by parsing a block of expressions up to the
terminating C<}>. All other elements response by calling their own
C<parse_expr()> method and returning themselves as a single expression (or
undef if they don't yield an expression).

=head2 parse_word()

This method parses the element as a word.  If an element can represent
a word then it should return itself (C<$self>).  Otherwise it should 
return C<undef>.  The default method in the base class returns C<undef>.

=head2 parse_dotop()

This method is called to parse a token immediately after a dotop.  In the 
usual case we would expect to find a word after a dotop.  Hence, the 
word element (L<Template::TT3::Element::Word>) responds to this method.
Other elements that can appear after a dotop include numbers and the 
C<$> and C<@> sigils.  

    [% foo.bar       %]
    [% items.0       %]
    [% users.$uid    %]
    [% album.@tracks %]

All other elements inherit the default method which returns C<undef>

=head2 parse_args()

This method parses the elements as an argument list.  The only element
that responds to this method is the left parenthesis (C<(> - implemented 
in L<Template::TT3::Element::Construct::Parens>).  All other elements 
inherit the default method which returns C<undef>.

=head2 parse_signature()

This is a wrapper around the L<parse_args()> method which is used in 
place of L<parse_args()> when a function appears on the left side of 
an assignment or in a named block/sub declaration.

    [% bold(text) = "<b>$text</b>" %]
    
    [% sub add(x,y) { x + y } %]
    
    [% sub html_elem(name, %attrs, @content) {
          '<' name attrs.html_attrs '>'
            content.join
          '</' name '>'
       }
    %]

=head2 parse_filename()

This method is called to parse an element as a filename.  Words, keywords
and quoted strings all constitute valid filenames (or filename parts) and
implement methods that respond accordingly.  The dot (C<.>) and slash 
(C</>) may also appear in filenames.  

Any of these elements will scan forwards for any other filename tokens and
combine them into a single filename string. Consider the C<site/header.tt3>
filename specified for the C<fill> command in the example below:

    [% fill site/header.tt3 %]

The filename is initially scanned as five separate tokens: 'site', '/',
'header', '.', and 'tt3'.  The C<parse_filename()> method will reconstitute
them into a single string.

Elements that do not represent valid filename parts inherit the default
method which returns C<undef>

=head2 parse_postfix($lhs, \$element, $scope, $prec)

This method is called to parse postfix operators that can appear after a
variable name. This includes the C<--> post-decrement and C<++> post-increment
operators, the C<()> parenthesis that denote function arguments, and the 
C<[]> and C<{}> operators for accessing list and hash items.

    foo--
    bar++
    bar(10,20)
    score[n]
    user{name}

Technically speaking, those last three are I<post-circumfix> operators, but
we're not too worried about technical details here. The important thing is
that I<postfix> operators in this implementation are those that can only
appear directly after a variable name with I<no> intervening whitespace.

Most elements are I<not> postfix operators.  The default C<parse_postfix()>
method simply returns the C<$lhs> expression.  

=head2 parse_infix($lhs, \$element, $scope, $prec)

This method is called to parse binary infix operators.  The element on 
the left of the operator is passed as the first argument, followed by the 
usual element reference (C<\$element> / C<$token>), scope (C<$scope>) and 
optional precedence level (C<$prec>).

Elements that represent infix operators will parse their right hand side from
the following expression and return themselves. All other elements inherit the
default method which returns the C<$lhs> argument.

=head2 parse_follow()

This is used to parse follow-on blocks, e.g. C<elsif> or C<else> following
an C<if>.  It is probably going to be renamed as C<parse_branch()>.

=head2 parse_lvalue()

This is a temporary hack.  It may no longer be a temporary hack by the time
you read this, but I just didn't get around to updating the documentation.

=head1 EVALUATION METHODS

The following methods are used to evaluate expressions to yield some value or
values. Each expects a single argument - C<$context>. This is a reference to a
L<Template::TT3::Context> object which encodes the state of the world (mostly
in terms of variables defined) at a point in time.

=head2 text($context)

Evaluates the element expression in the context of C<$context> and returns
the text generated by it.  Any non-text values will be coerced to text.
This is the method that is called against expressions that are embedded
in template blocks:

    [% foo %]               # $foo_element->text($context)

=head2 value()

Evaluates the element expression in the context of C<$context> and returns the
raw value generated by it. This is the method that is called on expression
that yield their value to some other expression. e.g. values on the right hand
side of an assignment such as the variable C<bar> in the following example:

    [% foo = bar %]         # $bar_element->value($context)

=head2 values()

Evaluates the element expression in the context of C<$context> and returns the
raw value or values generated by it. This is the method that is called on 
expression that yield their values to some other expression. e.g. values 
passed as arguments to a function or method call.

    [% foo(bar) %]          # $bar_element->values($context)
    [% foo(@bar) %]         # $at_bar_element->values($context)

Most elements return the same thing from C<values()> as they do for C<value()>
(one is usually an alias for the other).

TODO: more on this

=head2 list_values() (TODO: rename to items())

TODO: more on this

=head2 pairs()

TODO: more on this

=head2 VIEW METHODS

=head2 view()

=head2 view_guts()

=head2 ERROR REPORTING AND DEBUGGING METHODS

=head2 remaining_text()

=head2 branch_text()

=head2 signature_error()

=head2 fail_undef_data()

=head2 undefined_in_error()

=head2 error_nan()

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>, L<Template::TT3::Base>, L<Template::TT3::Elements> and
all the C<Template::TT3::Element::*> subclass modules.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

