package Template::TT3::Service::Input;

use Template::TT3::Class
    version     => 2.70,
    debug       => 0,
    base        => 'Template::TT3::Service';


sub serve {
    my ($self, $env, $source) = @_;
    my $context  = $env->{ context };
    my $template = $env->{ input } || $self->{ template }
        || return $self->error_msg( missing => 'input' );

    return $context->any_template($template)->fill_in($context);
}

1;