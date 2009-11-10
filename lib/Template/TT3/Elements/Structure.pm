# TODO change this to Exprs

package Template::TT3::Element::Block;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots :eval_args BLANK',
    constant  => {
        SEXPR_FORMAT => "<block:\n  %s\n>",
    },
    alias     => {
        value  => \&text,
        values => \&text,
    };


sub generate {
    $_[CONTEXT]->generate_block(
        $_[SELF]->[EXPR],
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

sub OLD_value {
    [
        map { $_->values($_[CONTEXT]) } 
        @{ $_[SELF]->[EXPR] } 
    ];
}

sub OLD_values {
    @{ $_[0]->value($_[1]) } 
}

sub text {
    join(
        BLANK,
        map { $_->text($_[1]) } 
        @{ $_[0]->[EXPR] } 
#        @{ $_[0]->value($_[1]) }
    );
}

1;