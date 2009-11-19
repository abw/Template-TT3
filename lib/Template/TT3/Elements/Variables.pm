#-----------------------------------------------------------------------
# Template::TT3::Element::Variable
#
# Element representing a variable name in a parse tree.
#-----------------------------------------------------------------------

package Template::TT3::Element::Variable;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'variable',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT => '<variable:%s>', 
#        SEXPR_FORMAT => '<variable:%s%s>', 
#        SEXPR_ARGS   => "<variable:\n  <name:%s>\n%s\n>", 
    },
    alias => {
        source        => 'token',
        values        => \&value,       # default to scalar context
        variable_list => \&variable,    # subclasses may redefine
    };


sub as_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance token
    $$token = $self->[NEXT];
    
    # TODO ask scope to lookup variable from the symbol table

    return $$token->as_postfix($self, $token, $scope, $prec);
    
    #$self->[ARGS] = $$token->as_args($token, $scope);
    
    # TODO: allow () [] {} following variable word
    #return $$token->as_postfix($self, $token, $scope, $prec);
    
    # variables can be followed by postops (postfix and infix operators)
    #return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub generate {
    $_[CONTEXT]->generate_variable(
        $_[SELF]->[TOKEN],
    );
}


sub sexpr {
    return sprintf(
        $_[SELF]->SEXPR_FORMAT,
        $_[SELF]->[TOKEN],
    );

    # TODO: won't need args once we have a 'var_apply' element
    my $args = $_[SELF]->[ARGS];
    my $format;
    
    if ($args) {
        $args = $args->sexpr;
        $args =~ s/^/  /gsm;
        $format = $_[SELF]->SEXPR_ARGS;
    }
    else {
        $args = '';
        $format = $_[SELF]->SEXPR_FORMAT;
    }
    sprintf(
        $format,
        $_[SELF]->[TOKEN],
        $args
    );
}


sub variable {
    $_[SELF]->debug("variable($_[SELF]->[TOKEN])") if DEBUG;
    $_[CONTEXT]->{ variables }
         ->var( $_[SELF]->[TOKEN] );
}


sub text {
    $_[SELF]->debug("text($_[SELF]->[TOKEN])") if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->text;
}


sub value {
    $_[SELF]->debug("value($_[SELF]->[TOKEN])") if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->value;
}


sub list_values {
    $_[SELF]->debug("list_values($_[SELF]->[TOKEN])") if DEBUG;
    # explicitly force list context
    $_[SELF]->variable( $_[CONTEXT] )->values;
}


sub assign {
    $_[SELF]->variable($_[CONTEXT])->set($_[2]);
#    return ();
}


sub name {
    $_[SELF]->debug("name($_[SELF]->[TOKEN])") if DEBUG;
    $_[SELF]->[TOKEN];
}


# Signature for a function, e.g. foo(a, b, @c, %d) is:
# {  a => '$', b => '$', c => '@', d => '%',       # name => type
#    '$' => ['a', 'b'],     # list of scalar positional args
#    '@' => 'c',            # positional args collector
#    '%' => 'd' ,           # named parameters collector
# }
# Each argument in an argument list fills its own entry into the
# shared hash array, or barfs if there's a conflict with an existing
# argument.

sub signature {
    my ($self, $name, $signature) = @_;
    my $sigil = '$';
    $signature ||= { };

    # we can't be an argument in a function signature if we have args
    # or we have a dynamic name, e.g. $$foo
    return $self->bad_signature( bad => $name )
        if $self->[ARGS] || $self->[EXPR];

    # fail if there's an existing argument with same name
    my $token = $self->[TOKEN];
    return $self->bad_signature( dup => $name, $token )
        if $signature->{ $token };

    # save (name => type) pair
    $signature->{ $token } = $sigil;

    # add name to '$' scalar argument list
    my $args = $signature->{ $sigil } ||= [ ];
    push(@$args, $token);

    return $signature;
}


# TODO: source() should add args


#-----------------------------------------------------------------------
# Template:TT3::Element::Variable::Apply
#
# A wrapper around a variables and a list of arguments used to represent
# function application, e.g. foo(a,b), rather than just a function 
# reference, e.g. foo.  Not very efficient at the moment, but I'm not 
# worrying about optimisation ATM.
#-----------------------------------------------------------------------

package Template::TT3::Element::Variable::Apply;

use Template::TT3::Class 
    debug     => 0,
    base      => 'Template::TT3::Element::Variable',
    view      => 'apply',
    constants => ':elements',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<apply:%s%s>",
        SEXPR_ARGS    => "<args:%s>",
        SOURCE_FORMAT => '%s(%s)',
    };


sub as_postfix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    $self->accept($token);

    # TODO: should copy $lhs->[EXPR] and optimise away a whole layer
    $self->[EXPR] = $lhs;
    $self->[ARGS] = $$token->as_exprs($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );

    $$token->is( $self->FINISH )
        || return $self->missing( $self->FINISH, $token);

    $$token = $$token->next;
    
    $self->debug("EXPR: $self->[EXPR]   ARGS: $self->[ARGS]") if DEBUG;

    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub variable {
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply( 
#       $_[SELF]->[ARGS]->values( $_[CONTEXT] )
        $_[SELF]->[ARGS]->params( $_[CONTEXT] )
    );

#    my @params = $_[SELF]->[ARGS]->params( $_[CONTEXT] );
#    $_[SELF]->debug("variable() params: ", $_[SELF]->dump_data(\@params)) if DEBUG or 1;
#    $_[SELF]->debug("ARGS: ", $_[SELF]->[ARGS]);
#    $_[SELF]->debug("PARAMS: ", $_[SELF]->[ARGS]->params( $_[CONTEXT] ));
}


sub variable_list {
    $_[SELF]->debug('variable_list() args are ', $_[SELF]->[ARGS]->source) if DEBUG;
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply_list( 
#       $_[SELF]->[ARGS]->values( $_[CONTEXT] )
        $_[SELF]->[ARGS]->params( $_[CONTEXT] )
    );
}


sub list_values {
    $_[SELF]->variable_list( $_[CONTEXT] )->values;
}


sub sexpr {
    my $self = shift;
    my $name = $self->[EXPR]->sexpr;
    my $args = $self->[ARGS]->sexpr( $self->SEXPR_ARGS );
    for ($name, $args) {
        s/^/  /gsm;
    }
    sprintf(
        $self->SEXPR_FORMAT,
        "\n" . $name,
        "\n" . $args . "\n"
    );
}


sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT,
        $self->[EXPR]->source,
        $self->[ARGS]->source,
    );
}



#-----------------------------------------------------------------------
# Template:TT3::Element::Sigil
#
# Base class for sigils that prefix a variable: $ @ %
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    constants => ':elements FORCE',
    constant  => {
        SEXPR_FORMAT  => "<%s:%s>",
        SOURCE_FORMAT => '%s%s',
    },
    alias     => {
        SIGIL => 'token',
    };


sub as_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance past sigil token
    $$token = $self->[NEXT];
    
    # fetch next expression using our ultra-high RHS precedence, along with
    # the FORCE argument to ensure that we get at least one token if we can
    # TODO: this should be as_variable() so that keywords are rejected
    $self->[EXPR] = $$token->as_expr(
        $token, $scope, $self->[META]->[RPREC], FORCE
    )   || return $self->missing( expression => $token );
    
    # TODO: allow other () [] {} to follow
    #return $$token->as_postfix($self, $token, $scope, $prec);
    
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}

sub sexpr {
    my $self = shift;
    my $body = $self->[EXPR]->sexpr;
    $body =~ s/^/  /gsm;
    sprintf(
        $self->SEXPR_FORMAT,
        $self->SIGIL,
        "\n" . $body . "\n",
    )
}

sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT,
        $self->SIGIL,
        $self->[EXPR]->source
    );
}



#-----------------------------------------------------------------------
# Template:TT3::Element::Sigil::Item
#
# Element for the scalar item sigil '$' which forces scalar context.
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil::Item;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil',
    constants => ':elements ARRAY';

# NOTE: I considered change the as_expr() / as_variable() methods to return 
# the next variable expression directly so we can avoid these indirections.
# However, that's a path to FAIL because the '$' sigil should always force
# scalar context.  Admittedly it's only required for edge cases like @$foo()
# where you want to call foo() in a scalar context, $foo(), but then want
# to unpack the list reference returned by it.  If we remove the $ at parse
# time then we end up with @$foo() being @foo() resulting in foo() being 
# called in list context with no further unpacking being done.

sub value {
    $_[SELF]->[EXPR]->value($_[CONTEXT]);
}

sub values {
    $_[SELF]->[EXPR]->value($_[CONTEXT]);
}

sub text {
    $_[SELF]->[EXPR]->text($_[CONTEXT]);
}



#-----------------------------------------------------------------------
# Template:TT3::Element::Sigil::List
#
# Element for the list context sigil '@' which forces list context on 
# function/methods calls and unpacks list references.
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil::List;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil',
    constants => ':elements ARRAY SPACE';


sub value {
    $_[SELF]->debug('value()') if DEBUG;
    my @values = $_[SELF]->[EXPR]->list_values($_[CONTEXT]);
    # not sure if we should always return a list in scalar context?
    # e.g. should C<foo = @bar> be like C<(foo) = @bar> or C<foo = [@bar]>
    return @values > 1
        ? \@values
        :  @values;
}

sub values {
    $_[SELF]->debug('values()') if DEBUG;
    $_[SELF]->[EXPR]->list_values($_[CONTEXT]);
}

sub text {
    join(SPACE, $_[SELF]->values($_[CONTEXT]) );
}

sub signature {
    my ($self, $name, $signature) = @_;
    my $sigil = $self->[TOKEN];
    $signature ||= { };

    # we can't be an argument in a function signature if we have args
    # or we have a dynamic name, e.g. $$foo
#    return $self->bad_signature( bad => $name )
#        if $self->[ARGS] || $self->[EXPR];

    # fail if there's an existing list argument
    # FIXME: we should delegate to the expression - that must check args,
    # dynamic name, etc.
    my $token = $self->[EXPR]->[TOKEN];

    # check that there isn't already an argument with a '@' sigil - we 
    # can't have two
    return $self->bad_signature( dup_sigil => $name, $token, $sigil )
        if $signature->{ $sigil };

    # save (name => type) pair
    $signature->{ $sigil } = $token;
    $signature->{ $token } = $sigil;

    return $signature;
}



#-----------------------------------------------------------------------
# Template:TT3::Element::Sigil::Hash
#
# Element for the hash context sigil '%' which forces hash context on 
# function/methods calls and unpacks hash references.
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil::Hash;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil::List',
    constants => ':elements';

our $TEXT_FORMAT = '%s: %s';
our $TEXT_JOINT  = ', ';


sub value {
    $_[SELF]->debug('value()') if DEBUG;
    return { 
        $_[SELF]->[EXPR]->hash_values($_[CONTEXT])
    };
}

sub values {
    $_[SELF]->debug('values()') if DEBUG;
    $_[SELF]->[EXPR]->hash_values($_[CONTEXT]);
}

sub text {
    my $hash = $_[SELF]->value($_[CONTEXT]);
    join(
        $TEXT_JOINT,
        map { sprintf($TEXT_FORMAT, $_, $hash->{ $_ }) }
        sort keys %$hash
    );
}




#-----------------------------------------------------------------------
# dotop
#-----------------------------------------------------------------------

package Template::TT3::Element::Variable::Dot;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::Binary
                  Template::TT3::Element',
    as        => 'filename',        # dots allowed in filenames, e.g. foo.tt3
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT => '<dot:%s%s%s>',
        SEXPR_ARGS   => "<args:%s>",
    };


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # Operator precedence - if our leftward binding precedence is less than
    # or equal to the precedence requested then we return the LHS.  
    # The 'or equal' part gives us left asociativity so that "a + b + c"
    # is parsed as "(a + b) + c"
    return $lhs 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # otherwise this operator has a higher precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # TODO: as_dotop() should fetch word/expression, then we look for args
    $self->debug("asking $$token for dotop") if DEBUG;
    
    $self->[RHS] = $$token->as_dotop($token, $scope, $self->[META]->[LPREC])
        || return $self->missing( expression => $token );

    $self->[ARGS] = $$token->as_args($token, $scope);

    $self->debug("DOT as_postop() [$self->[LHS]] [$self->[RHS]] [$self->[ARGS]]") if DEBUG;
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub value {
    $_[SELF]->debug("fetching value()") if DEBUG;
    return $_[SELF]->variable($_[CONTEXT])->value;
}

sub variable {
    $_[SELF]->[LHS]->variable($_[CONTEXT])->dot(
        $_[SELF]->[RHS]->value($_[CONTEXT]),
        $_[SELF]->[ARGS]
            ? [$_[SELF]->[ARGS]->values($_[CONTEXT])]
            : ()
    );
}

sub sexpr {
    my $self = shift;
    my $lhs  = $self->[LHS]->sexpr;
    my $rhs  = $self->[RHS]->sexpr;
    my $args = $self->[ARGS];
    $args = $args 
        ? $args->sexpr( $self->SEXPR_ARGS )
        : '';
    for ($lhs, $rhs, $args) {
        next unless length;
        s/^/  /gsm;
    }
    sprintf(
        $self->SEXPR_FORMAT,
        "\n" . $lhs,
        "\n" . $rhs,
        "\n" . $args . "\n"
    );
}



1;
