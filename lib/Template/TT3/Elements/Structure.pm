package Template::TT3::Element::Block;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots BLANK',
    constant  => {
        SEXPR_FORMAT => "<block:\n  %s\n>",
    };

sub generate {
    my $self = $_;
    $_[1]->generate_block(
        $_[0]->[EXPR],
    );
}

sub sexpr {
    my $self = shift;
    my $body = join(
        "\n  ", 
        map { $_->sexpr } 
        @{ $self->[EXPR] }
    );
    sprintf(
        $self->SEXPR_FORMAT,
        $body
    );
}

sub value {
    [
        map { $_->values($_[1]) } 
        @{ $_[0]->[EXPR] } 
    ];
}

sub values {
    @{ $_[0]->value($_[1]) } 
}

sub text {
    join(
        BLANK,
        @{ $_[0]->value($_[1]) }
    );
}

1;