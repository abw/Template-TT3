package Template::TT3::App;

use Template::TT3::Class
    version   => 2.718,
    debug     => 0,
    base      => 'Badger::App Template::TT3::Base';

our $OPTIONS = [
    {
        name   => 'verbose|-v=0',
        about  => 'Verbose mode',
    },
    {
        name   => 'debug|-d=0',
        about  => 'debug mode',
    },
    {   
        name   => 'help|-h',
        about  => 'Show this help',
        method => 'help',
    },
];

sub run {
    my $self = shift;
    my $app  = $self->{ app };
    $self->validate;

    if ($app->{ verbose }) {
        $self->credits;
    }
}


sub status {
    my $self = shift;
    my $app  = $self->{ app };

    if ($app->{ verbose }) {
        $self->debug("running in verbose mode");
    }
    else {
        $self->debug("NOT running in verbose mode");
    }

    if ($app->{ debug }) {
        $self->debug("running in debug mode");
    }
    else {
        $self->debug("NOT running in debug mode");
    }
}


1;

