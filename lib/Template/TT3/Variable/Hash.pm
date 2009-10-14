package Template::TT3::Variable::Hash;

use Template::TT3::Class
    version  => 0.01,
    base     => 'Template::TT3::Variable',
    constants => ':type_slots';

sub dot {
    my ($self, $name, $args) = @_;

    $self->[VARIABLES_SLOT]->use_var( 
        $name,
        $self->[VALUE_SLOT]->{$name}, 
        $self, 
        $args
    );
}



    
1;
