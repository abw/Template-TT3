package Template::TT3::Service::Footer;

use Template::TT3::Class
    version     => 2.70,
    debug       => 0,
    base        => 'Template::TT3::Service';


sub serve {
    my ($self, $env, $source) = @_;
    my $context = $env->{ context };
    my $footer  = $env->{ footer } || $self->{ template }
        || return $source->($env);

    return $source->($env)
         . $context->any_template($footer)->fill_in($context);
}


1;