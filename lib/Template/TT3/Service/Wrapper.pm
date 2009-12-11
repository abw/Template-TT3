package Template::TT3::Service::Wrapper;

use Template::TT3::Class
    version     => 2.70,
    debug       => 0,
    base        => 'Template::TT3::Service';


sub serve {
    my ($self, $env, $source) = @_;
    my $context = $env->{ context };
    my $wrapper = $env->{ wrapper } || $self->{ template }
        || return $source->($env);

    return $context->any_template($wrapper)->fill_in(
        $context->with( content => $source->($env) )
    );
}

1;