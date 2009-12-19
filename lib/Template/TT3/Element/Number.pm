package Template::TT3::Element::Number;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Literal',
    view      => 'number',
    alias     => {
#        parse_number => 'self',        # this is already a number op
#        parse_dotop  => 'advance',
        number       => 'value',       # our token contains the number
    };

sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance token
    $$token = $self->[NEXT];
    
    # numbers can be followed by infix operators, e.g. 400 + 20
    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}

sub sexpr {
    return '<number:' . $_[SELF]->[TOKEN] . '>';
}

1;
