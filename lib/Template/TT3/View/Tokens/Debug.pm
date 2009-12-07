package Template::TT3::View::Tokens::Debug;

use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::View::Tokens',
    constants   => 'ARRAY :elements',
    utils       => 'params refaddr',
    import      => 'class',
    config      => 'show_pos=1 show_refs=0',
    auto_can    => 'can_view',
    init_method => 'configure';


our $TRIM_TEXT = 64;



#-----------------------------------------------------------------------
# general purpose methods for emitting elements
#-----------------------------------------------------------------------

sub emit {
    my $self = shift;
    join(
        "\n",
        grep { defined }
        map  { ref $_ eq ARRAY ? @$_ : $_ }
        @_
    );
}


sub emit_head {
    my ($self, $name, $pos, $body, @attrs) = @_;
    my $attrs = $self->emit_attrs($pos, @attrs);
    return "<$name$attrs:$body>";
}


sub emit_attrs {
    my ($self, $pos, @args) = @_;
    my @attrs;

    push(@attrs, '@' . $pos) 
        if defined $pos && $self->{ show_pos };

    if (@args) {
        my $params = params(@args);
        push(
            @attrs, 
            map { "$_=$params->{ $_ }" } 
            grep { defined $params->{ $_ } }
            sort keys %$params
        );
    }
    return @attrs 
        ? '[' . join(', ', @attrs) . ']'
        : '';
}


sub emit_body {
    my ($self, $name, $pos, $body) = @_;
    $pos = defined $pos ? '@' . $pos : '';
    $body =~ s/^/$self->{ pad }/gm if $self->{ indent };
    chomp $body;
    return "<$name$pos:\n$body\n>";
}


sub emit_set {
    my ($self, $name, $value) = @_;
    return "<SET:$name=$value>";
}


sub emit_text {
    my ($self, $text) = @_;
    $text =~ s/\n/\\n/g;
    $text =~ s/\t/\\t/g;
    $text = substr($text, 0, $TRIM_TEXT) . '...' 
        if $TRIM_TEXT && length($text) > $TRIM_TEXT - 3;
    return $text;
}


sub show_refs {
    $_[0]->{ show_refs } ? $_[1]->view_guts : ()
}


#-----------------------------------------------------------------------
# view methods
#-----------------------------------------------------------------------

sub view_element {
    my ($self, $element) = @_;
    $self->emit_head(
        $element->class->id,
        $element->[POS],
        $element,
        $self->show_refs($element),
    )
}


sub view_eof {
    my ($self, $elem) = @_;
    my $attrs = $self->emit_attrs($elem->[POS], $self->show_refs($elem));
    return "<EOF$attrs>";
}


sub can_view {
    my ($self, $name) = @_;
    
    $self->debug("can_view($name)") if DEBUG;

    return 
        unless $name =~ s/^view_//;
        
    return sub {
        $_[0]->emit_head(
            $name, 
            $_[1]->[POS],
            $_[0]->emit_text( $_[1]->[TOKEN] ),
            $_[0]->show_refs($_[1]),
        );
    };
}



__END__

