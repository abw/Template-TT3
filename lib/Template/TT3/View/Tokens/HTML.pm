package Template::TT3::View::Tokens::HTML;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tokens Template::TT3::View::HTML',
    import    => 'class',
    codec     => 'html',
    config    => [
        'view=source',
    ],
    constants => ':elements',
    constant  => {
        ATTR    => '%s="%s"',
        ELEMENT => "<%s%s>%s</%s>",
    };
    


our $TRIM_TEXT = 128;
our $AUTOLOAD;


sub view_tokens {
    my ($self, $tokens) = @_;
    my $view = $self->{ view };

    $self->debug("viewing as $view")
        if DEBUG;
    
    if ($view eq 'source') {
        return $self->emit(
            map { $_->view($self) }
            @$tokens
        );
    }
    elsif ($view eq 'tokens') {
        return $self->emit(
            map { $self->dump_token($_) }
            @$tokens
        );
    }
    else {
        return $self->error_msg( invalid => view => $view );
    }
}



our $CUSTOM_TYPES = {
    'boolean.or'  => 'binary operator',
    'boolean.and' => 'binary operator',
    'squote'      => 'squote string',
};

sub dump_token {
    my ($self, $token) = @_;
    my $type = $token->type;
    $type = $CUSTOM_TYPES->{ $type } || $type;
    for ($type) {
        s/\./ /g;
        s/tag(\w+)/tag_$1/;
    }
    $self->div(
        "$type element",
        $self->div(
            head => 
            $self->span( "info type" => $type ),
            $self->span( "info posn" => '@' . $token->[POS] ),
            $self->span( source => $self->tidy_text( encode($token->[TOKEN]) ) ),
        ),
    );
}


#-----------------------------------------------------------------------
# most of the mundane methods can be auto-generated
# TODO: make this an auto_can handler
#-----------------------------------------------------------------------

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
        postfix squote dquote parens list hash pair variable dot filename
        apply fragment pod_verbatim pod_format_start pod_format_end pod_blank
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
      is as if for raw with just fill into blockdef slot sub
    )
);


#-----------------------------------------------------------------------
# custom methods
#-----------------------------------------------------------------------

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

