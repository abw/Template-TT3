package Template::TT3::Element::Command::Fill;

use Template::TT3::Class::Element 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    parse_expr => 'name',
    type       => 'fill',
    view       => 'fill',
    constants  => 'ARRAY',
    constant   => {
        SEXPR_FORMAT => "<fill:%s>",
    },
    alias      => {
        value  => \&text,
        values => \&text,
    };

sub sexpr {
    my $self   = shift;
    sprintf(
        $self->SEXPR_FORMAT,
        $self->[EXPR]->sexpr
    );
}
    

sub text {
    my ($self, $context) = @_;
    my $template = $self->[EXPR]->template($context, $self->[ARGS]);
    return $template->fill_in($context);
#    return "TODO: fill $template";
}


1;
