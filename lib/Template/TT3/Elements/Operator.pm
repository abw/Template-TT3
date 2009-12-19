#-----------------------------------------------------------------------
# Template::TT3::Element::Operator;
#
# Base class for operator mixins.  Not that this is NOT a subclass of
# Template::TT3::Element as we don't want to inherit all the default 
# methods.  This allows us to put an operator mixin at the start of the
# base path (@ISA) for a subclass.  This will add the methods defined
# below, but leave any other methods to be inherited from subsequent 
# base classes in the @ISA list.
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator;

use Template::TT3::Class 
    version   => 3.00,
    constants => ':elements',
    utils     => 'xprintf',
    view      => 'operator';



sub FIXED_parse_dotop {
    # Operators can't be dotops by default - this is really a nasty quick
    # hack to mask the parse_dotop() method in T::Element::Number which 
    # allows a number to be used as a dotop.  Because all our numeric
    # ops are subclasses of T::E::Number (the core problem, I think) that
    # means they inherit the parse_dotop() method and think they are valid
    # syntax after a dot, e.g. foo.**

    # FIXME: this include 'or' 'and', etc, and other keywords (unless we 
    # patch in another method in the keyword/command class to override it,
    # but then it's starting to get messy).  This is a quick hack.
    
    return undef;
}


sub OLD_no_rhs_expr { 
    my ($self, $token) = @_;
    
    # We throw an error for now.  It's conceivable that we might want to
    # do some error recovery here.  We could generate a warning, wind the
    # token pointer forward to the next terminator token, and return a  
    # parse_error element containing information about the error.  But for
    # now, we'll just throw an error.
    my $next = $token 
        && $$token->skip_ws->[TOKEN]
        || '';
    
    $self->syntax_error_msg( 
        $$token,
        length $next
            ? ( no_rhs_expr_got => $self->[TOKEN], $next )
            : ( no_rhs_expr     => $self->[TOKEN] )
    );
}


sub debug_op {
    $_[0]->debug_at(
        { format => '[pos:<pos>] <msg>]', pos => $_[0]->[POS] },
        xprintf(
            $_[0]->DEBUG_FORMAT, 
            $_[0]->[TOKEN],
            map { $_ ? ($_->source, $_->value($_[1])) : ('', '') }
            $_[0]->[LHS],
            $_[0]->[RHS],
        )
    );
}


sub generate {
    $_[1]->generate_operator(
        $_[0]->[TOKEN],
        $_[0]->[LHS],    # ->generate($_[1]),
        $_[0]->[RHS],    # ->generate($_[1]),
    );
}




#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::Unary;
#
# Mixin class for unary operators.
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Unary;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator',
    view      => 'unary',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT  => '<unary:<op:%s>%s>', 
        SOURCE_FORMAT => '%s%s', 
    };


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TOKEN],
        $_[0]->[LHS]
            ? $_[0]->[LHS]->sexpr
            : $_[0]->[RHS]->sexpr
    );
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::Prefix;
#
# Mixin class for unary prefix operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Prefix;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary',
    view      => 'prefix',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT => '<prefix:<op:%s>%s>', 
        DEBUG_FORMAT => 'prefix: [<1>] [<4> => <5>]',
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;

    # operator precedence
    return undef 
        if $prec && $self->[META]->[RPREC] < $prec;

    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[RPREC])
        || $self->fail_missing( expression => $token );

    # carry on...
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[TOKEN],
        $_[0]->[RHS]->source
    );
}


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TOKEN],
        $_[0]->[RHS]->sexpr
    );
}


sub generate {
    $_[1]->generate_prefix(
        $_[0]->[TOKEN],
        $_[0]->[RHS],    # ->generate($_[1]),
    );
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::Postfix;
#
# Mixin class for unary postfix operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Postfix;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary',
    view      => 'postfix',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT => '<postfix:<op:%s>%s>', 
        DEBUG_FORMAT => 'postfix: [<2> => <3>] [<1>]',
    };


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return undef 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # stash away the expression on our left
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # carry on...
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[LHS]->source,
        $_[0]->[TOKEN],
    );
}


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TOKEN],
        $_[0]->[LHS]->sexpr
    );
}


sub generate {
    $_[1]->generate_postfix(
        $_[0]->[TOKEN],
        $_[0]->[LHS],   #->generate($_[1]),
    );
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::Binary;
#
# Mixin class for binary operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Binary;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator',
    view      => 'binary',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT  => '<binary:<op:%s>%s%s>', 
        SOURCE_FORMAT => '%s %s %s', 
        DEBUG_FORMAT  => 'infix: [<1>] [<2> => <3>] [<4> => <5>]',
    };


sub source {
    sprintf(
        $_[0]->SOURCE_FORMAT, 
        $_[0]->[LHS]->source,
        $_[0]->[TOKEN], 
        $_[0]->[RHS]->source,
    );
}


sub sexpr {
    sprintf(
        $_[0]->SEXPR_FORMAT, 
        $_[0]->[TOKEN],
        $_[0]->[LHS]->sexpr,
        $_[0]->[RHS]->sexpr,
    );
}


sub generate {
    $_[1]->generate_binop(
        $_[0]->[TOKEN],
        $_[0]->[LHS],
        $_[0]->[RHS],
    );
}


sub left_edge {
    $_[0]->[LHS]->left_edge;
}


sub right_edge {
    $_[0]->[RHS]->right_edge;
}


sub parse_expr {
    my ($self, $token, $scope) = @_;
    return undef;
}




#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::Infix;
#
# Mixin class for non-chaining infix operators.
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Infix;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary',
    constants => ':elements';


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # Operator precedence - if our leftward binding precedence is less than
    # or equal to the precedence requested then we return the LHS.  
    return $lhs 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # otherwise this operator has a higher precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # Parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter.  Note that 
    # we also set the $force (1) flag
    
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
        || return $self->fail_missing( expression => $token );

    # CHECK: I originally thought that non-chaining ops should return here,
    # but that scuppers an expression like: "x < 10 && y > 30" as the '<'
    # returns after '10', leaving '&&' unparsed.

    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
    
    # non-chaining infix operators always return at this point
    return $self;
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::InfixLeft;
#
# Mixin class for binary operators with left associativity
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::InfixLeft;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary',
    constants => ':elements';


sub parse_infix {
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
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
        || return $self->fail_missing( expression => $token );
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::InfixRight;
#
# Mixin class for binary operators with right associativity
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::InfixRight;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary',
    constants => ':elements';


sub parse_infix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # This is identical to parse_infix() in T::E::O::InfixLeft all but one 
    # regard.  If we have an equal precedence between two consecutive 
    # operators then we bind the RHS pair tighter than the LHS pair, e.g.
    # "a = b = c" is parsed as "a = (b = c)".  To implement this we just 
    # need to change <= to < in the comparison.  Equal operators now 
    # continue instead of returning as they do for left associativity.
    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    # otherwise this operator has a >= precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher or equal precedence can bind tighter
    $self->[RHS] = $$token->parse_expr($token, $scope, $self->[META]->[LPREC], 1)
        || return $self->fail_missing( expression => $token );
    
    # at this point the next token might be a lower or equal precedence 
    # operator, so we give it a chance to continue with the current operator
    # as the LHS
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Operator::InfixRight;
#
# Mixin class for binary assignment operators.  This adds a custom text() 
# method that calls the value() method but returns nothing.  This is how 
# we make the assignment expressions generate no output, e.g. [% a = 10 %].
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Assignment;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator',
    constants => ':elements';
    
sub text {
    $_[SELF]->value($_[CONTEXT]);
    return ();
}



1;

__END__

=head1 Binary Infix Operators

The C<Template::TT3::Element::Operator::Binary> module defines a base mixin
class for all binary operators.  Note that this is I<not> a subclass of 
C<Template::TT3::Element>, or any other class for that matter.  The 
operator class are designed to be used as mixin base classes.  So they 
only define the one or two methods that are related specifically to it

C<Template::TT3::Element::Operator::Infix> defines a base class for all
non-chaining binary operators (NOTE: the non-chaining bit doesn't work at
present - it behaves just like the regular chaining infix left operator - I
need to look at this). It defines the C<parse_infix()> method which subclasses
can inherit to implement the operator precedence parsing mechanism required
for non-chaining (see earlier note) infix binary operators.

C<Template::TT3::Element::Operator::InfixLeft> defines a base class
for all leftward associative binary operators.  It defines the C<parse_infix()>
method to handle operator precedence parsing for left associative infix
binary operators.

C<Template::TT3::Element::Operator::InfixRight> defines a base class
for all leftward associative binary operators.  It defines the C<parse_infix()>
method to handle operator precedence parsing for right associative infix
binary operators.

In all cases the C<parse_infix()> method does more-or-less the same thing.

    sub parse_infix {
        my ($self, $lhs, $token, $scope, $prec) = @_;

        # Operator precedence
        return $lhs 
            if $prec && $self->[META]->[LPREC] <= $prec;

        # store expression on LHS of operator
        $self->[LHS] = $lhs;
    
        # advance token past operator
        $$token = $self->[NEXT];
    
        # Parse the RHS expression
        $self->[RHS] = $$token->parse_expr(
            $token, $scope, $self->[META]->[LPREC], 1
        )
        || return $self->fail_missing( expression => $token );

        # parse any more binary operators following
        return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
    }

The C<parse_infix()> method is called with the following arguments:

    $self       # the current element object (a binary operator token)
    $lhs        # the expression element on the left of the operator
    $token      # a reference to the current token (initially equals \$self)
    $scope      # the current lexical scope (TODO)
    $prec       # precedence limit

The C<$prec> precedence limit is the key to operator precedence parsing.
If the current operator has a precedence higher than the C<$prec> requested
then it binds tighter than the preceding operator or expression.  In this
case, C<parse_infix()> should continue.  If on the other hand the current 
operator has a lower precedence that that requested, the C<parse_infix()> 
method should return the C<$lhs> expression immediately.

The difference between the infix, infix left and infix right methods all
comes down to what happens when the precedence in the same.  For left
associative operators, the method should return early.  This results in 
equal precedence operators grouping to the left.

    a + b + c       # parsed as: (a + b) + c

For right associative operators, the method should continue when the
precedence is equal.

    a = b = c       # parsed as: a = (b = c)

In terms of code, the only difference is in the comparison operator in the 
first line of (proper) code in the C<parse_infix()> method.

C<Template::TT3::Element::Operator::InfixLeft>:

    return $lhs 
        if $prec && $self->[META]->[LPREC] <= $prec;

C<Template::TT3::Element::Operator::InfixRight>:

    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

So we just need to change the C<E<lt>=> comparison to C<E<lt>>.

NOTE: the non-chaining infix operator should do something different, but
I'm not 100% sure what.  Needs looking at.  For now it works like the infix
left.

After the precedence check, we store the C<$lhs> parameter in the C<LHS>
slot of the element.

        # store expression on LHS of operator
        $self->[LHS] = $lhs;

We then update the C<$token> token reference to point to the token 
immediately following the current operator token (C<$self-E<gt>[NEXT]>).

        # advance token past operator
        $$token = $self->[NEXT];

On the right of the operator we expect another expression so we call the
C<parse_expr()> method on the next token.  

        # Parse the RHS expression
        $self->[RHS] = $$token->parse_expr(
            $token, $scope, $self->[META]->[LPREC], 1
        )
        || return $self->fail_missing( expression => $token );

We pass it the reference to the current token, C<$token>, so that it can
advance the token pointer to consume tokens from the input stream. We also
pass it the current lexical scope, C<$scope>, although that isn't being used
yet, so you can ignore it for now.  The next argument is the precedence of
the current operator.  This ensures that the C<parse_expr()> method will only 
consume any further binary operators that have a higher precedence (i.e.
bind tighter).

The final option is a C<$force> flag which tells the next token that we
really, really want an expression. Otherwise it would be a syntax error to
have a binary operator without an expression on the right hand side.

This is required as a special dispensation to command keywords that act
as operators (e.g. C<if>, C<for>, etc).  They have a lower precedence than
all the other operators.  This is required so that an expression like this:

    a = b if c

Is parsed as:

    (a = b) if c

And not:

    a = (b if c)

(This is a failing of the current TT2 parser).

By giving keyword operators like C<if> and C<for> a lower precedence than
the C<=> assignment operator, we can have the regular operator precedence
parser take care of it.

However, we also want to be able to commands as the right hand side of 
variable expressions. Like this, for example:

    a = if a { b } else { c }

Or this:

    h = do { fill my/header }

In the usual case, the keywords following the C<=> assignment (C<if> and C<do>
in these rather contrived examples) would decline and immediately return
from the parse_expr() method because their precedence is lower than that of
the assignment operator.

The additional C<$force> flag is a hint telling them that it's OK for them 
to return themselves even if their precedence is lower than the one we 
specified as the C<$prec> argument.  Any operators following on from the
command keyword are then parsed as per the specified precedence.

Now that we have an expression for the right hand side of the operator we are
all done.  Well, almost.  There may be further infix binary operators following
this one.  They haven't been consumed yet because their precedence was lower
than ours.  So we finally call the C<parse_infix()> method on the next token
(following any whitespace) and pass C<$self> as the left hand side expression,
along with the current token reference, the scope and the precedence that 
we were called with.

        # parse any more binary operators following
        return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
    }
