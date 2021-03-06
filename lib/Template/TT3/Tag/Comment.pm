package Template::TT3::Tag::Comment;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag::Inline',
    constants => ':elements';


sub tokenise {
    my ($self, $input, $output) = @_;
    
    # gobble everything up to the end token
    $$input =~ /$self->{ match_to_end }/cg
        || return $self->error_msg( no_end => $self->{ end } );
        
    # change the previous token (the comment start tag token) to be a 
    # comment token and append the comment body and end token to it
    $output->last->become('comment')->extend($1, $2);

    $self->debug("matched to end of comment tag: [$1] [$2]") if DEBUG;

    return $2;
}
    

1;


__END__

=head1 NAME

Template::TT3::Tag::Comment - comment tags

=head1 SYNOPSIS

    use Template::TT3::Scanner;
    use Template::TT3::Tag::Comment;
    
    my $tag = Template::TT3::Tag::Comment->new(
        start => '[#',
        end   => '#]',
    );
    
    my $scanner = Template::TT3::Scanner->new(
        tagset => {
            comment => $tag
        }
    );
    
    my $tokens = $scanner->scan($some_text);

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Tag> which implements the 
TT3 comment tag.

    [# this is a comment tag #]

=head1 METHODS

The following methods are defined in addition to those inherited from the
L<Template::TT3::Tag::Inline>, L<Template::TT3::Tag>, L<Template::TT3::Base>
and L<Badger::Base> base classes.

=head2 tokenise($input,$output)

Custom tokenisation method for scanning comment tags.  The start token for
the comment tag is the last token in C<$output> when this method is called.
It scans to the end of the comment tag and appends the comment to the end 
of the start tag token.  It then changes the start token type to be a comment.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

L<Template::TT3::Tag::Inline>, L<Template::TT3::Tag>, L<Template::TT3::Base>
and L<Badger::Base>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

