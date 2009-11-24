package Template::TT3::Element::Command::Just;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Command::With',
    view       => 'just',
    constants  => ':elements',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub text {
    my ($self, $context) = @_;
    
    return $self->[BLOCK]->text( 
        $context->just(
            $self->[ARGS]->pairs($context)
        ) 
    );
}



1;