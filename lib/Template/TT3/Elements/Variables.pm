package Template::TT3::Element::Variable;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots';


sub as_expr {
    my ($self, $token, $scope, $prec) = @_;
#    $prec ||= 0;
#    $self->debug("variable $self->[TOKEN] as_expr($prec)");

    # TODO: allow () [] {} following variable word
    
    # advance token
    $$token = $self->[NEXT];
    
    # variables can be followed by postops (postfix and infix operators)
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}

sub generate {
    $_[1]->generate_variable(
        $_[0]->[TOKEN],
    );
}


package Template::TT3::Element::Block;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots';

sub generate {
    my $self = $_;
    $_[1]->generate_block(
        $_[0]->[EXPR],
    );
}

1;
