package Template::TT3::Service::Output;

use Template::TT3::Class
    version => 2.70,
    debug   => 0,
    base    => 'Template::TT3::Service',
    config  => 'name=output options';


sub serve {
    my ($self, $env, $pipeline) = @_;

    my $output = $env->{ $self->{ name } } 
        || $self->{ template };      # it's not really a template
        
    my $options = $env->{ output_options }
        || $self->{ options }
        || { };

    return defined $output
        ? $self->hub->output( $pipeline->($env), $output, $options )
        : $pipeline->($env);

}

1;

