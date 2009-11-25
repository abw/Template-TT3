package Template::TT3::Element::Role::Pair;

use Template::TT3::Class 
    version   => 2.718,
    debug     => 0,
    mixins    => 'parse_pair',
    constants => ':elements :precedence';


# We have to do this in two steps.  First, any element that can start a
# pair (words, strings, etc) should have a parse_pair() method that calls 
# parse_expr() to parse itself.  Then we can tell when we've reached the end
# of a parameter list when we reach the first element that doesn't respond
# to the parse_pair() method call.  In practical terms, that means the
# majority of elements that inherit the default parse_pair() method which 
# returns undef, indicating that it cannot start a pair.  This includes 
# keywords, operators and block delimiters like ';', '%]' and '{'.  
#
# However, the $self token is just the start of an expression that could
# be an assignment like "foo = 10", a pair like "foo => 20" or it might 
# just be the variable by itself like "foo" which we treat as syntactic 
# sugar for 'foo=foo'.  So we then call as_pair() on whatever element is 
# returned as the expression.  If the element doesn't implement its own 
# as_pair() method (e.g. if the expression turned out to be "a + b + 10" 
# which we can't reasonably make a pair from) then the element will inherit
# the default as_pair() method which throws a syntax error.

sub parse_pair {
    my ($self, $token, $scope) = @_;
    my $expr  = $self->parse_expr($token, $scope, ARG_PRECEDENCE) || return;
    return $expr->as_pair($token, $scope);
}


# TODO: I don't think we want to mix this in by default because some elements
# (e.g. variable) will need to define their own as_pair() method.

sub as_pair {
    return $_[SELF];
}


1;