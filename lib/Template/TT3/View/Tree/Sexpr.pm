package Template::TT3::View::Tree::Sexpr;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tree',
    auto_can  => 'can_view',
    constants => ':elements',
    constant  => {
        ELEMENT => "<%s%s>%s</%s>",
    };

sub view_block {
    my ($self, $block) = @_;
    $self->div( 
        block => join(
            "\n", 
            map { $_->view($self) }
            $block->expressions
        )
    )
}

sub construct {
    my ($self, $type, $elem) = @_;
    sprintf(
        '<%s:%s>',
        $type,
        $elem->[EXPR]->view($self)
    );
}

    
sub view_list {
    $_[SELF]->construct( list => $_[1] );
}

sub view_hash {
    $_[SELF]->construct( hash => $_[1] );
}

sub view_parens {
    $_[SELF]->construct( hash => $_[1] );
}


sub block_sexpr_TODO {
    my $self   = shift;
    my $format = shift || $self->SEXPR_FORMAT;
#        SEXPR_FORMAT  => "<block:%s>",

    my $body   = join(
        "\n",
        map { $_->sexpr } 
        @{ $self->[EXPR] }
    );
    $body =~ s/^/  /gsm if $body;
    sprintf(
        $format,
        $body ? ("\n" . $body . "\n") : ''
    );
}



sub can_view {
    return undef;
    
    my ($self, $name) = @_;
    my $class = ref $self || $self;
    my $method = "view_$name()";

    return sub {
        "No $method method defined in $class";
    }
}


1;