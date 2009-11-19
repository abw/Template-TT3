#-----------------------------------------------------------------------
# Template::TT3::Element::Whitespace - literal whitespace elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Whitespace;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    import    => 'class',
    constants => ':elements',
    constant  => {
        is_whitespace => 1,
    },
    alias     => {
        skip_ws => 'next_skip_ws',
    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    shift->next_skip_ws($_[0])->skip_delimiter(@_);
}


sub as_expr {
    # we can always skip whitespace to get to an expression
    shift->next_skip_ws($_[0])->as_expr(@_);
}


sub as_block {
    # same for a block
    shift->next_skip_ws($_[0])->as_block(@_);
}


sub generate {
    $_[1]->generate_whitespace(
        $_[0]->[TOKEN]
    );
}

sub view {
    $_[1]->view_whitespace($_[0]);
}



#-----------------------------------------------------------------------
# Template::TT3::Element::TagStart - tag start token
#-----------------------------------------------------------------------

package Template::TT3::Element::TagStart;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Whitespace',
    constants => ':elements';

*skip_ws = \&next_skip_ws;


sub next_skip_ws {
    # In the case of scan-time control directives (e.g. [? TAGS '<* *>' ?] ) 
    # we want to hide the tokens inside the directive from the expression 
    # parser because they have already been interpreted at tokenising time 
    # and don't equate to runtime expressions that the parser understands.
    # So the tokeniser for these tags adds a BRANCH entry in the start token 
    # for the directive that points to the end token.  Whenever we skip_ws 
    # or next_skip_ws on one of these start tokens (as we always do when 
    # a whitespace token as_expr() method is called) then we jump straight
    # down to the end token and continue from there.  For regular tags, we
    # just advance to the next token as usual.
    ($_[0]->[BRANCH] && $_[0]->[BRANCH]->skip_ws($_[1]))
 || ($_[0]->[NEXT]   && $_[0]->[NEXT]->skip_ws($_[1]))

#    my $self = $_[0];
#    $self->debug("[$self]   NEXT:[$self->[NEXT]]  GOTO:[$self->[GOTO]]");
#    $self->debug("skipping to end of tag [$self->[GOTO]]\n") if $self->[GOTO];
#    $self->debug("tag start next_skip_ws(): ${$_[1]}  next is $self->[NEXT] (calling skip_ws())");

}


sub generate {
    $_[1]->generate_tag_start(
        $_[0]->[TOKEN]
    );
}

sub view {
    $_[1]->view_tag_start($_[0]);
}




package Template::TT3::Element::Comment;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Whitespace',
    constants => ':elements';
    

sub generate {
    $_[1]->generate_comment(
        $_[0]->[TOKEN]
    );
}

sub view {
    $_[1]->view_comment($_[0]);
}


package Template::TT3::Element::Eof;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elements',
    constant  => {
        eof   => 1,
    },
    alias     => {
        as_expr => 'null',
    };

sub generate {
    '';
}

sub view {
    $_[1]->view_eof($_[0]);
}


1;
