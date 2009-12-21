package Template::TT3::Variable::Missing;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable::Undef',
    constant  => {
        type    => 'missing',
        defined => 0,
    },
    messages  => {
        bad_dot   => 'Invalid dot operation: <1>.<2> (<1> is missing)',
#        undefined => '"%s" is missing',
    };

sub text {
    my ($self, $element) = @_;

    # If we were passed an element reference then we raise the error 
    # against that so that it can decorate the exception with line 
    # number, source code, etc.  Otherwise we just throw a plain error.
    
    return ($element || $self)
        ->fail( data_missing => $self->fullname );
}

1;
