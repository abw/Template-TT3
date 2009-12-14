package Template::TT3::Service::Input;

use Template::TT3::Class
    version => 2.70,
    debug   => 0,
    base    => 'Template::TT3::Service',
    config  => 'name=input';


sub serve {
    my ($self, $env, $pipeline) = @_;

    my $input = $self->template( $env )
        || return $self->error_msg( missing => $self->{ name } );
    
    return $input->fill_in( $env->{ context } );
}

sub no_source {
    # It's OK if no source pipeline is specified for us to connect to 
    # because we're an input service so we generate a source.
    return undef;
}

1;

