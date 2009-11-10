package Template::TT3::Element::Assign;

use Template::TT3::Elements::Literal;
use Template::TT3::Elements::Operator;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::InfixRight
                  Template::TT3::Element',
    import    => 'class',
    constants => ':elem_slots :eval_args',
    constant  => {
        SEXPR_FORMAT => '<assign:<%s><%s>>', 
    },
    alias     => {
        number => \&value,
        values => \&value,      # TODO: parallel assignment
    };


# The assignment operator needs a special-case implementation of as_postop()
# to handle the assignment of keyword command expressions to variables.
#
# e.g. 
#    [% a = do { b c } %]
#
# The assign operator should always have an RHS value (not to mention an LHS,
# but that's always the case because as_postop() would never have been called 
# if it didn't).  The assign operator calls $token->next->as_expr() passing 
# its own  left precedence as an argument.  This ensures that the expression 
# following the assignment is correctly parsed wrt operator precedence.  
#
# However, if a command keyword follows the '=' then it would normally return 
# undef from as_expr().  This is because keywords have a lower precedence than 
# the assignment operator (this is required so that C<a=b if c> is parsed as 
# C<(a=b) if c> and not C<a = (b if c)>).
#
# To work around this, the assignment operator passes an additional final 
# argument to as_expr(), a 'force' flag which tells the next token that it 
# can ignore the specified precedence for its own initial precedence check.  
# This allows command keywords to return themselves even though their 
# precedence is lower.  Any as_postop() follow-on that the command keyword
# does will use the precedence specified.  Thus, the $force flag only affects
# the token immediately to the right of the assignment operator (exclluding
# any whitespace which we merrily skip over).

sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    # save LHS
    $self->[LHS] = $lhs;
    $$token = $self->[NEXT];
    
    # NOTE: extra $force flag (1) tells the token it can bypass its own
    # precedence check before continuing.  
    $self->[RHS] = $$token->as_expr($token, $scope, $self->[META]->[LPREC], 1) 
        || return $self->missing( expression => $self->[TOKEN] );
    
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub value {
#    $_[SELF]->debug("assign [$_[SELF]->[LHS]] [$_[SELF]->[RHS]]");
    $_[SELF]->[LHS]
            ->variable( $_[CONTEXT] )        # fetch LHS as a variable
            ->set(                           # set it to RHS value
                $_[SELF]->[RHS]->value( $_[CONTEXT] )
              )->value;
}


sub text {
    # when evaluated as text, e.g. [% a = 10 %], an assignment evaluates
    # itself but returns nothing.
    shift->value(@_);
    return ();
}

1;


