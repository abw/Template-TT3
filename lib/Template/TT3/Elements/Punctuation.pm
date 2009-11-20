package Template::TT3::Element::Punctuation;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elements';
    

sub as_expr {
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


sub as_expr {
    my ($self, $token, @args) = @_;
    $$token = $self->[NEXT] if $token;
    $self->[NEXT]->as_expr($token, @args);
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


sub as_block {
    my ($self, $token, $scope, $parent, $follow) = @_;
    my (@exprs, $expr);
    
    $parent ||= $self;

    $self->debug("as_block()") if DEBUG;
 
    # skip past token any whitespace, then parse expressions
    my $block = $$token->next_skip_ws($token)->as_exprs($token, $scope)
        || return $parent->missing( $self->ARG_BLOCK, $token );

    # if the parent defines any follow-on blocks (e.g. elsif/else for if)
    # then we look to see if the next token is one of them and activate it
    if ($follow && $$token->skip_ws($token)->in($follow)) {
        $self->debug("Found follow-on token: ", $$token->token) if DEBUG;
        return $$token->as_follow($block, $token, $scope, $parent);
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
        as_expr    => 'null',
        as_block   => 'null',
        as_postop  => 'reject',
        terminator => 'next_skip_ws',
    };

#sub as_expr {
#    shift->next_skip_ws($_[0])->as_expr(@_);
#}

# TODO: as_terminator() to terminate and return preceeding block  




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

