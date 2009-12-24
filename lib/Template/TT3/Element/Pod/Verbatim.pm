package Template::TT3::Element::Pod::Verbatim;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Text',
    view      => 'pod_verbatim',
    alias     => {
        value  => \&text,
        values => \&text,
    };


sub text {
    my ($self, $context) = @_;
    $context->show(
        'pod.verbatim' => {
            body => $self->[TOKEN]
        }
    );
}
    
1;