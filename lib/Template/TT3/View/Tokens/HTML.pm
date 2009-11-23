package Template::TT3::View::Tokens::HTML;

#use utf8;
use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tokens',
    import    => 'class',
    codec     => 'html',
    constants => ':elements',
    constant  => {
        ATTR    => '%s="%s"',
        ELEMENT => "<%s%s>%s</%s>",
    };


our $TRIM_TEXT = 64;
our $AUTOLOAD;


sub HTML {
    my ($name, $attrs, @content) = @_;
    my $attr = $attrs
        ? join(
            ' ',
            '',     # dummy first entry to get leading space
            map { sprintf( ATTR, $_ , encode( $attrs->{ $_ } ) ) }
            sort keys %$attrs
          )
        : '';
    
    return sprintf( ELEMENT, $name, $attr, join('', grep { defined } @content), $name );
}

sub span {
    my $self      = shift;
    my $css_class = shift;
    HTML( span => { class => $css_class }, @_ );
}

class->methods(
    map {
        my $type = $_;              # lexical copy for closure
        "view_$type" => sub {
            $_[0]->span( $type, encode $_[1]->[TOKEN] )
        }
    }
    qw(
        text comment padding html element terminator string
        literal word keyword number filename unary binary prefix
        postfix squote dquote parens list pair variable
    )
);

class->methods(
    map {
        my $type = $_;              # lexical copy for closure
        "view_$type" => sub {
            $_[0]->span( "$type keyword", $_[1]->[TOKEN] )
        }
    }
    qw(
      is as if for raw
    )
);

sub view_html_element {
    my ($self, $elem) = @_;
    $self->span( 'html_element keyword' => $elem->[TOKEN] );
}

sub view_whitespace {
    my ($self, $elem) = @_;
    my $text = $elem->[TOKEN];
    $text =~ s/\n/\n<span class="nl"><\/span>/g;
    $self->span( whitespace => $text );
}

sub view_tag_start {
    my ($self, $elem) = @_;
    return '<span class="tag">'
        . $self->span( tag_start => $elem->[TOKEN] );
}

sub view_tag_end {
    my ($self, $elem) = @_;
    return $self->span( tag_end => $elem->[TOKEN] )
        . '</span>';
}

sub view_eof {
    my ($self, $elem) = @_;
    return $self->span( eof => '--EOF--' );
}

1;

__END__

=head1 NAME

Template::TT3::View::Tokens::HTML - generates an HTML view of template tokens

=head1 SYNOPSIS

    use Template::TT3 'Template';
    
    # create a template
    my $template = Template( text => 'Hello [% world %]' );
    
    # generate an HTML view of the tokens.
    print $template->tokens->html;
    
=head1 DESCRIPTION

# TODO

=head1 METHODS

=head2 new()

# TODO

=head2 generate($item)

TODO

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

