package Template::TT3::Element::Delimiter;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    constants => ':elements BLANK',
    constant  => {
        FINISH => 'end',
    },
    alias     => {
        parse_expr => 'null',
    };



sub skip_delimiter {
    $_[SELF]->next_skip_ws( $_[CONTEXT] )
            ->skip_delimiter( $_[CONTEXT] );
}


sub parse_body {
    my ($self, $token, $scope, $parent, $follow) = @_;
    my (@exprs, $expr, $begfrag, $endfrag, $fragtok);
    
    $parent ||= $self;

    $self->debug("parse_body(), parent is $parent->[TOKEN]") if DEBUG;
 
    # skip past token any whitespace, then parse expressions
    my $block = $$token->next_skip_ws($token)->parse_block($token, $scope)
        || return $parent->fail_missing($self->ARG_BLOCK, $token);

    # if the parent defines any follow-on blocks (e.g. elsif/else for if)
    # then we look to see if the next token is one of them and activate it

    # TODO: check that it's safe to assume $follow is always $parent->FOLLOW
    # my $follow = $parent->FOLLOW;
    
    if ($follow && $$token->skip_ws($token)->in($follow)) {
        $self->debug("Found follow-on token: ", $$token->token) if DEBUG;
        return $$token->parse_follow($block, $token, $scope, $parent);
    }

    # otherwise the next token must be our FINISH token (e.g. end)
    my $finish = $self->FINISH;
    my $endtok = $$token->skip_ws($token);

    return $parent->fail_missing($finish, $token)
        unless $$token->is($finish, $token);
    
    # if a fragment follows then it must match the parent command token
    # (e.g. for ... end#for) or the explicit fragment added to the token
    # passed to us as $fragment (e.g. for#outer ... end#outer)
    if ($fragtok = $$token->parse_fragment($token, $scope)) {
        $begfrag = $parent->[FRAGMENT] ? $parent->[FRAGMENT]->[TOKEN] : BLANK;
        $endfrag = $fragtok->[TOKEN];

        $self->debug(
            "comparing end fragment: [$endfrag] to parent [$parent->[TOKEN]] [$begfrag]"
        ) if DEBUG;

        return ($fragtok || $endtok)->fail_syntax( 
            bad_fragment => $parent->[TOKEN] . ($begfrag ? '#' . $begfrag : ''),
                            $endtok->[TOKEN] . '#' . $endfrag
        ) 
        unless $parent->[TOKEN] eq $endfrag 
            or $begfrag && $begfrag eq $endfrag;
    }

    # return the $block we built, not $self which is the delimiter
    return $block;
}


1;
