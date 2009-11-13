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
    constants => ':elem_slots :eval_args',
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
    constants => ':eval_args :elem_slots',
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
    return $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply( 
        $_[SELF]->[ARGS]->values( $_[CONTEXT] )
    );

    $_[SELF]->debug("variable() fetching variable from $_[SELF]->[EXPR]") if DEBUG;
    my $v = $_[SELF]->[EXPR]->variable( $_[CONTEXT] ); 
    $_[SELF]->debug("variable() var: $v") if DEBUG;
    my $args = $_[SELF]->[ARGS]->values( $_[CONTEXT] );
    $_[SELF]->debug("variable() args: $args") if DEBUG;
    my $res = $v->apply( 
        $_[SELF]->[ARGS]->values( $_[CONTEXT] )
    );
    $_[SELF]->debug("variable() result: $res") if DEBUG;
    return $res;
    
}

sub variable_list {
    $_[SELF]->debug('variable_list() args are ', $_[SELF]->[ARGS]->source) if DEBUG;
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply_list( 
        $_[SELF]->[ARGS]->values( $_[CONTEXT] )
    );
}

sub list_values {
    $_[SELF]->debug('list_values()') if DEBUG;
    $_[SELF]->debug("calling variable_list() on expr: $_[SELF]->[EXPR]") if DEBUG;
    my $vl = $_[SELF]->variable_list( $_[CONTEXT] );
    $_[SELF]->debug("variable_list: $vl, values are ", $vl->values) if DEBUG;
    return $vl->values;
    
    $_[SELF]->[EXPR]->variable_list( $_[CONTEXT] )->values;
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
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots :eval_args FORCE',
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
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil::Item;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil',
    constants => ':elem_slots :eval_args ARRAY';

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
#-----------------------------------------------------------------------

package Template::TT3::Element::Sigil::List;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Sigil',
    constants => ':elem_slots :eval_args ARRAY';


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
    join('', $_[SELF]->values($_[CONTEXT]) );
}



#-----------------------------------------------------------------------
# dotop
#-----------------------------------------------------------------------

package Template::TT3::Element::Dot;

use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Operator::Binary
                  Template::TT3::Element',
    as        => 'filename',        # dots allowed in filenames, e.g. foo.tt3
    constants => ':elem_slots :eval_args';


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
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter
    $self->[RHS] = $$token->as_dotop($token, $scope, $self->[META]->[LPREC])
        || return $self->error("Missing expression after dotop");

    $self->debug("DOT as_postop() [$self->[LHS]] [$self->[RHS]]") if DEBUG;
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub value {
    my ($self, $context) = @_;
    my $lhs = $self->[LHS]->variable($context);
    my $rhs = $self->[RHS]->value($context);
    $self->debug("DOT value() [$self->[LHS] => $lhs] [$self->[RHS] => $rhs]\n") if DEBUG;
    $lhs->dot($rhs)->value($context);
}


sub variable {
    # args are ($self, $context)
    # $self->[LHS]->variable($context)->dot($rhs->value($context));
    $_[SELF]->[LHS]->variable($_[CONTEXT])->dot(
        $_[SELF]->[RHS]->value($_[CONTEXT])
    );
}




1;
