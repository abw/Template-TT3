package Template::TT3::Element::Pod::Paragraph;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Text',
    view      => 'pod_paragraph',
    alias     => {
        value  => \&text,
        values => \&text,
    };


sub parse_expr {
    my ($self, $token, $scope) = @_;
    my (@exprs, $expr);

    $$token = $self->[NEXT];

    while (! $$token->whitespace 
          && ($expr = $$token->parse_expr($token, $scope))) {
        push(@exprs, $expr);
    }

    $self->[BLOCK] = $self->[META]->[ELEMS]->create(
        block => $self->[TOKEN], $self->[POS], \@exprs
    );

    $self->debug(
        "paragraph parsed ", 
        scalar(@{ $self->[BLOCK]->[EXPR] } ), 
        " elements\n",
        "next token is $$token => ", 
        $$token->source
    ) if DEBUG;
        
    return $self;
}

sub text {
    my ($self, $context) = @_;
    return $context->show(
        'pod.paragraph' => {
            body => $self->[BLOCK]->text($context)
        },
    );
}

1;