package Template::TT3::Service::Header;

use Template::TT3::Class
    version     => 2.70,
    debug       => 0,
    base        => 'Template::TT3::Service';


sub serve {
    my ($self, $env, $source) = @_;
    my $context = $env->{ context };
    my $header  = $env->{ header } || $self->{ template }
        || return $source->($env);

    return $context->any_template($header)->fill_in($context)
         . $source->($env);
}

1;