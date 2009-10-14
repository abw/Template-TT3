package Template::TT3::Variable::Undef;

use Template::TT3::Class
    version  => 0.01,
    base     => 'Template::TT3::Variable',
    messages => {
        bad_dot => 'Invalid dot operation: <1>.<2> (<1> is undefined)',
    };

sub dot {
    my ($self, $name) = @_;
    return $self->error_msg( bad_dot => $self->fullname, $name );
}

    
1;
