package Template::TT3::Op::Subtract;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Op::Binop',
    constants => ':op_slots';

sub value {
    my $self = shift;
    return $self->[LHS]->value(@_)
         - $self->[RHS]->value(@_);
}


1;
