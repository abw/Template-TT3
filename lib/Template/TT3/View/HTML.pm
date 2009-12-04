package Template::TT3::View::HTML;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View',
    codec     => 'html',
    constants => 'HASH';


sub HTML {
    my ($self, $name, $attrs, @content) = @_;

    # attributes can be a single string as a shortcut for (class => $css)
    $attrs = { class => $attrs } 
        if $attrs and ref $attrs ne HASH;

    my $body = join('', grep { defined } @content);
    my $attr = $attrs
        ? join(
            ' ',
            '',     # dummy first entry to get leading space
            map { sprintf('%s="%s"', $_ , encode( $attrs->{ $_ } ) ) }
            sort keys %$attrs
          )
        : '';
    
    return sprintf( 
        '<%s%s>%s</%s>',
        $name, $attr, $body, $name
    );
}


sub span {
    shift->HTML( span => @_ );
}


sub div {
    shift->HTML( div => @_ );
}


sub branch {
    my $self = shift;
    my $name = shift;
    
    return $self->div( 
        lc($name) => $self->span( branch => $name ), 
        @_
    );
}

1;


