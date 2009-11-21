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
#    view      => 'separator',
    constants => ':elements',
    constant  => {
        is_delimiter => 1,
    },
    alias     => {
        skip_delimiter => 'next_skip_ws',
    };


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
    constants => ':elements',
    constant  => {
        is_delimiter => 1,
        FINISH       => 'end',
    };
#    alias     => {
#        skip_delimiter => 'next_skip_ws',
#    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    $_[0]->next_skip_ws($_[1])->skip_delimiter($_[1]);
}


sub parse_body {
    my ($self, $token, $scope, $parent, $follow) = @_;
    my (@exprs, $expr);
    
    $parent ||= $self;

    $self->debug("parse_body()") if DEBUG;
 
    # skip past token any whitespace, then parse expressions
    my $block = $$token->next_skip_ws($token)->parse_block($token, $scope)
        || return $parent->missing( $self->ARG_BLOCK, $token );

    # if the parent defines any follow-on blocks (e.g. elsif/else for if)
    # then we look to see if the next token is one of them and activate it
    if ($follow && $$token->skip_ws($token)->in($follow)) {
        $self->debug("Found follow-on token: ", $$token->token) if DEBUG;
        return $$token->parse_follow($block, $token, $scope, $parent);
    }

    # otherwise the next token must be our FINISH token (end)
    return $parent->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH, $token );

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
        parse_expr    => 'null',
        parse_body   => 'null',
        parse_infix  => 'reject',
        terminator => 'next_skip_ws',
    };

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

