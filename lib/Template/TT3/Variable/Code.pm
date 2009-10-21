package Template::TT3::Variable::Code;

use Template::TT3::Class
    version   => 0.01,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    messages  => {
    };

sub apply {
    my $self = shift;
        
    $self->[META]->[VARS]->use_var( 
        $self->[NAME], 
        $self->[VALUE]->(@_), 
        $self,
    );
}
    
1;
