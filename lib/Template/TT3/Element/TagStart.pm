package Template::TT3::Element::TagStart;

use Template::TT3::Class::Element
    version => 2.69,
    debug   => 0,
    base    => 'Template::TT3::Element::Whitespace',
    view    => 'tag_start',
    alias   => {
        skip_ws => \&next_skip_ws,
    };


sub next_skip_ws {
    # In the case of scan-time control directives (e.g. [? TAGS '<* *>' ?] ) 
    # we want to hide the tokens inside the directive from the expression 
    # parser because they have already been interpreted at tokenising time 
    # and don't equate to runtime expressions that the parser understands.
    # So the tokeniser for these tags adds a BRANCH entry in the start token 
    # for the directive that points to the end token.  Whenever we skip_ws 
    # or next_skip_ws on one of these start tokens (as we always do when 
    # a whitespace token parse_expr() method is called) then we jump straight
    # down to the end token and continue from there.  For regular tags, we
    # just advance to the next token as usual.
    return ($_[0]->[BRANCH] && $_[0]->[BRANCH]->skip_ws($_[1]))
        || ($_[0]->[NEXT]   && $_[0]->[NEXT]->skip_ws($_[1]))
}

1;


