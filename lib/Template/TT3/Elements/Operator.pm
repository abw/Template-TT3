die "Template::TT3::Elements::Operator is deprecated\n";

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
