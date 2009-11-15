package Template::TT3::Element::Control::Tags;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    alias      => {
        text   => \&value,
        values => \&value,
    };

sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    $self->accept($token);

    # TODO: skip over '=' / 'is' / 'are'
#    $self->debug("TAGS next token is: $$token->[TOKEN]");

    $self->[EXPR] = $$token->as_expr($token, $scope)
        || return $self->missing( expression => $token );
    
#    $self->debug("TAGS expr: ", $self->[EXPR]->sexpr);
        
    return $self;
}

sub value {
    my $self = shift;
    $self->debug("evaluating TAGS");
    return ();
}

1;