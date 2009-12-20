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

__END__

=head1 NAME

Template:TT3::Element::TagStart - element representing a tag start token

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element::Whitespace> to
represent a token indicating the start of a template tag, e.g. C<[%>, C<%%>, 
C<[?>, etc.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element::Whitespace>, L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 next_skip_ws($token)

This method implements some custom handling for skipping over whitespace
when parsing tokens into an expression tree.

In the case of parse-time control directives (e.g. C<[? TAGS '(* *)' ?]>) 
we want to hide the tokens inside the directive from the expression 
parser because they have already been interpreted at tokenising time 
and don't equate to runtime expressions that the parser understands.

So the tokeniser for these tags adds a C<BRANCH> entry in the start token for
the directive that points to the end token. When either of the
C<next_skip_ws()> or L<skip_ws()> methods are called on one of these start
tokens (as we always do when a whitespace token
L<parse_expr()|Template::TT3::Element::Whitespace/parse_expr()> method is
called) then we jump straight down to the end token and continue from there.

For all other tags, we advance to the next token as usual.

=head2 skip_ws($token)

An alias to the L<next_skip_ws()> method.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_tag_start()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_tag_start()> method.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element::Whitespace>,
L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base> base
classes.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

The L<Template::TT3::Element::TagEnd> module implements a related element
used to represent the end of an embedded tag.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
