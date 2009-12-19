package Template::TT3::Element::Punctuation;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elements';
    

sub parse_expr {
    return undef;
}

sub OLD_generate {
    $_[1]->generate_punctuation(
        $_[0]->[TOKEN]
    );
}


#-----------------------------------------------------------------------
# TODO: separator
#-----------------------------------------------------------------------

package Template::TT3::Element::Separator;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Punctuation',
#   view      => 'separator',
    constants => ':elements',
    constant  => {
#        is_delimiter => 1,
    };


sub skip_separator {
    # we can always skip whitespace to skip over a delimiter
    $_[0]->next_skip_ws($_[1])->skip_separator($_[1]);
}

sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    $_[0]->next_skip_ws($_[1])->skip_delimiter($_[1]);
}

sub parse_expr {
    my ($self, $token, @args) = @_;
    $$token = $self->[NEXT] if $token;
    $self->[NEXT]->parse_expr($token, @args);
}


#-----------------------------------------------------------------------
# statement delimiter: ';' or '%]' or some other tag end
#-----------------------------------------------------------------------

package Template::TT3::Element::Delimiter;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Punctuation',
#    as        => 'block',
    constants => ':elements BLANK',
    constant  => {
        is_delimiter => 1,
        FINISH       => 'end',
    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    $_[0]->next_skip_ws($_[1])->skip_delimiter($_[1]);
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


#-----------------------------------------------------------------------
# Template::TT3::Element::TagEnd - tag end token
#-----------------------------------------------------------------------

package Template::TT3::Element::TagEnd;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Delimiter',
    view      => 'tag_end',
    constants => ':elements';
    


#-----------------------------------------------------------------------
# TODO: terminator
#-----------------------------------------------------------------------

package Template::TT3::Element::Terminator;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation',
    view      => 'terminator',
    constants => ':elements',
    constant  => {
        is_terminator => 1,
    },
    alias     => {
        parse_expr  => 'null',
        parse_body  => 'null',
        parse_infix => 'reject',
        terminator  => 'next_skip_ws',
    };


package Template::TT3::Element::Fragment;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Terminator',
    view      => 'fragment',
    constants => ':elements';


sub parse_fragment {
    my ($self, $token, $scope) = @_;
    $$token = $self->[NEXT];
    return $$token->parse_word($token, $scope)
        || $self->fail_missing( word => $token );
}

#sub parse_expr {
#    shift->next_skip_ws($_[0])->parse_expr(@_);
#}

# TODO: parse_terminator() to terminate and return preceeding block  




#-----------------------------------------------------------------------
# end
#-----------------------------------------------------------------------

package Template::TT3::Element::End;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Terminator',
    view      => 'keyword',
    constants => ':elements';


1;    

