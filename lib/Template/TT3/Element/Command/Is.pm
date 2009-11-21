package Template::TT3::Element::Command::Is;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Keyword',
    view       => 'is',
    constants  => ':elements',
    constant   => {
        SOURCE_FORMAT => '%s %s { %s }',
    },
    as         => 'block_expr',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub parse_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store LHS and advance token past keyword
    $self->[LHS] = $lhs;
    $self->accept($token);
    
    # parse block
    $self->[RHS] = $$token->parse_block($token, $scope)
        || return $self->missing( block => $token );
    
    # TODO: return assign node
    return $self;
}


sub text {
    # if an 'is' command has a LHS then it's like an assignment: foo is { xxx }
    # otherwise it's just an anonymous block container: is { xxx }
    $_[SELF]->[LHS]
        ? $_[SELF]->[LHS]
            ->variable( $_[CONTEXT] )
            ->set( $_[SELF]->[RHS]->text( $_[CONTEXT] ) )->BLANK
        : $_[SELF]->[RHS]->text( $_[CONTEXT] );
}


# Need to generalise this - it's disabled for now because it makes a test
# in t/control/html.t fail.  Ironically, the test is illustrating how the 
# html encoding is broken because keywords like 'is' don't have explicit
# html() methods.  So if I add the html() method then the test fails, 
# suggesting that the problem is fixed, prompting me to change and/or
# remove the test.  Technically speaking, it *is* solved for the 'is' 
# keyword, but it's not fixed for any of the others.  So I don't want to 
# be led into a false sense of security.

# sub html {
#     # if an 'is' command has a LHS then it's like an assignment: foo is { xxx }
#     # otherwise it's just an anonymous block container: is { xxx }
#     $_[SELF]->[LHS]
#         ? $_[SELF]->[LHS]
#             ->variable( $_[CONTEXT] )
#             ->set( $_[SELF]->[RHS]->html( $_[CONTEXT] ) )->BLANK
#         : $_[SELF]->[RHS]->html( $_[CONTEXT] );
# }


sub source {
    sprintf(
        $_[SELF]->SOURCE_FORMAT,
        $_[SELF]->[LHS]->source,
        $_[SELF]->[TOKEN],
        $_[SELF]->[RHS]->source,
    )
}

1;
