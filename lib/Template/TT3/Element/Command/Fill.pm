package Template::TT3::Element::Command::Fill;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args ARRAY',
    constant   => {
        SEXPR_FORMAT => "<fill:%s>",
    },
    alias      => {
        values => \&text,
        value  => \&text,
    };

sub sexpr {
    my $self   = shift;
    sprintf(
        $self->SEXPR_FORMAT,
        $self->[EXPR]->sexpr
    );
}
    

sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;
    my $lprec = $self->[META]->[LPREC];

    return undef
        if $prec && ! $force && $lprec <= $prec;

    $self->accept($token);
    
    $self->[EXPR] = $$token->skip_ws($token)->as_filename($token, $scope, $lprec)
        || return $self->missing( filename => $token );

    return $self;
}


sub text {
    return "TODO: fill ", $_[SELF]->[EXPR]->filename;
}


1;
