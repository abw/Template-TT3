package Template::TT3::Element::Delimiter;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    constants => 'BLANK',
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

    $self->debug(
        "parse_body(), parent is $parent->[TOKEN], follow is",
        $self->dump_data($follow)
    ) if DEBUG;
 
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


__END__

=head1 NAME

Template:TT3::Element::Delimiter - element for representing expression delimiters

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element> to
represent expression delimiters. It also acts as a base class for the 
L<Template::TT3::Element::TagEnd> module.

Delimiters are comprised of the end-of-tag tokens, e.g. C<%]>, C<?]>, etc., 
and also semi-colons used to delimit separate statements inside a single
tag:

    [% if foo %]
       ...    ^delimiter
    [% end %]

    [% if foo;
       ...   ^ delimiter
       end
    %]

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 skip_delimiter($token)

This method advances the element referenced by the C<$token> variable past
the current token and any subsequent whitespace or delimiter tokens.

=head2 parse_expr($token,$scope,$precedence)

This method returns C<undef> to indicate that a delimiter element does not 
yield an expression.

=head2 parse_body($token,$scope,$precedence)

This method is called when a keyword expects a block argument. If a delimiter
follows where a block is expected then it is assumed that the block continues
until a corresponding C<end> token (a
L<terminator|Template::TT3::Element::Terminator> token, not to be confused with
a cyborg sent from the future to kill Sarah Connor).

    [% if foo %]
       ...    ^delimiter starts block
    [% end %]
       ^terminator ends block
       

    [% if foo;
       ...   ^delimiter starts block
       end
    %] ^terminator ends block

It parses a block of content, checks that the terminator token is C<end>, 
and also, if any fragment is defined that it corresponds to the keyword
opening the block.

    [% if foo;
        ...
       end#if
    %]

The opening keyword may also have a fragment defined.

    %%  for#outer x in X
    %%      for#inner y in Y
                ...
    %%      end#inner
    %%  end#outer

If a fragment is specified for an C<end> token then it must match the 
keyword (e.g. C<if>, C<for>, etc), or the fragment name specified with 
the keyword, if there is one (e.g. C<outer> and C<inner> in the above
example).  Otherwise a syntax error will be thrown.

=head2 view($view)

This method is called by a L<Template::TT3::View> object as part of the double
dispatch process that is used to render views of template elements. It calls
the C<view_delimiter()> method against the view object passed as the only
argument, C<$view>. It passes itself as an argument to the
C<view_delimiter()> method.

=head1 CONSTANTS

The following constant method is defined.

=head2 FINISH

This is defined as the literal keyword C<end> and denotes the terminator
token that indicates the end of a block.  Subclasses may redefine this
constant method to return a different keyword.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module inherits methods from the L<Template::TT3::Element>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

It is constructed using the L<Template::TT3::Class::Element> class 
metaprogramming module.

It is the base class for the L<Template::TT3::Element::TagEnd> module.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
