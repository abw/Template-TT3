package Template::TT3::Element::Fragment;

use Template::TT3::Class::Element
    version   => 2.69,
    base      => 'Template::TT3::Element::Terminator',
    view      => 'fragment';


sub parse_fragment {
    my ($self, $token, $scope) = @_;
    $$token = $self->[NEXT];
    return $$token->parse_word($token, $scope)
        || $self->fail_missing( word => $token );
}

1;
